// Classificador automático de frases com IA (API do Claude / Anthropic).
//
// Recebe frases "soltas" (uma por linha), usa IA para:
//   1. classificar cada frase na categoria correta (só IDs válidos do app);
//   2. marcar conteúdo PROIBIDO (ódio, discriminação, sexual/violência
//      explícita, ilegal) — que é descartado;
//   3. evitar repetidas (dedup por texto, contra o input e, se existir,
//      contra content/existing_phrases.txt).
// Saída: content/generated_phrases.json — já no formato do conteúdo remoto,
// pronto pra publicar (o app mescla pelo `id`, sem duplicar).
//
// USO:
//   1) Tenha o catálogo: tool/categories.json (id+name das categorias).
//   2) Defina a chave da API:
//        Windows (PowerShell):  $env:ANTHROPIC_API_KEY = "sk-ant-..."
//        Linux/Mac (bash):      export ANTHROPIC_API_KEY="sk-ant-..."
//   3) Rode:
//        dart run tool/classify_phrases.dart tool/input_phrases.txt
//
// Requer apenas o pacote `http` (já é dependência do projeto). Não importa
// Flutter, então roda com `dart run` puro.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _apiUrl = 'https://api.anthropic.com/v1/messages';
// Modelo: Haiku é rápido/barato para classificação. Troque por
// 'claude-sonnet-4-6' se quiser julgamento ainda melhor de conteúdo.
const _model = 'claude-haiku-4-5-20251001';
const _batchSize = 25;

Future<void> main(List<String> args) async {
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('ERRO: defina a variável ANTHROPIC_API_KEY no ambiente.');
    exit(1);
  }

  // 1) Catálogo de categorias válidas (id -> name).
  final catFile = File('tool/categories.json');
  if (!catFile.existsSync()) {
    stderr.writeln('ERRO: tool/categories.json não encontrado.');
    exit(1);
  }
  final catalog = <String, String>{};
  for (final c in jsonDecode(catFile.readAsStringSync()) as List) {
    catalog[(c['id']).toString()] = (c['name']).toString();
  }

  // 2) Frases de entrada.
  final inputPath = args.isNotEmpty ? args.first : 'tool/input_phrases.txt';
  final inFile = File(inputPath);
  if (!inFile.existsSync()) {
    stderr.writeln('ERRO: arquivo de entrada não encontrado: $inputPath');
    exit(1);
  }
  final rawLines = inFile
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toList();

  // 3) Base de dedup (frases já existentes, opcional).
  final existing = <String>{};
  final existingFile = File('content/existing_phrases.txt');
  if (existingFile.existsSync()) {
    for (final l in existingFile.readAsLinesSync()) {
      final n = _norm(l);
      if (n.isNotEmpty) existing.add(n);
    }
  }

  // Remove duplicadas (exatas/normalizadas) já na entrada.
  final seen = <String>{};
  final toClassify = <String>[];
  var dup = 0;
  for (final line in rawLines) {
    final n = _norm(line);
    if (existing.contains(n) || seen.contains(n)) {
      dup++;
      continue;
    }
    seen.add(n);
    toClassify.add(line);
  }
  stdout.writeln('Entrada: ${rawLines.length} | novas: ${toClassify.length} '
      '| repetidas puladas: $dup');
  if (toClassify.isEmpty) {
    stdout.writeln('Nada para classificar.');
    return;
  }

  // 4) Classifica em lotes.
  final results = <_Result>[];
  for (var i = 0; i < toClassify.length; i += _batchSize) {
    final end = (i + _batchSize) > toClassify.length
        ? toClassify.length
        : i + _batchSize;
    final batch = toClassify.sublist(i, end);
    stdout.writeln('Classificando ${i + 1}..$end de ${toClassify.length}...');
    try {
      results.addAll(await _classifyBatch(apiKey, batch, catalog));
    } catch (e) {
      stderr.writeln('Falha no lote ${i + 1}..$end: $e');
    }
  }

  // 5) Filtra proibidas e IDs inválidos.
  final byCat = <String, List<String>>{};
  var prohibited = 0, invalid = 0;
  for (final r in results) {
    if (r.prohibited) {
      prohibited++;
      stderr.writeln('PROIBIDA (${r.reason}): ${r.phrase}');
      continue;
    }
    if (!catalog.containsKey(r.categoryId)) {
      invalid++;
      stderr.writeln('ID inválido "${r.categoryId}": ${r.phrase}');
      continue;
    }
    byCat.putIfAbsent(r.categoryId, () => []).add(r.phrase);
  }

  // 6) Monta o JSON no formato remoto.
  final outCats = [
    for (final entry in byCat.entries)
      {
        'id': entry.key,
        'name': catalog[entry.key],
        'phrases': entry.value,
      }
  ];
  final out = {
    'version': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'categories': outCats,
  };
  final outFile = File('content/generated_phrases.json');
  outFile.createSync(recursive: true);
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));

  stdout.writeln('\n==== RESUMO ====');
  stdout.writeln('Classificadas: ${results.length - prohibited - invalid} '
      'em ${byCat.length} categorias');
  stdout.writeln('Proibidas descartadas: $prohibited | IDs inválidos: $invalid');
  stdout.writeln('Arquivo gerado: content/generated_phrases.json');
}

String _norm(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

Future<List<_Result>> _classifyBatch(
    String apiKey, List<String> phrases, Map<String, String> catalog) async {
  final catList =
      catalog.entries.map((e) => '- ${e.key}: ${e.value}').join('\n');
  final numbered = [
    for (var i = 0; i < phrases.length; i++) '${i + 1}. ${phrases[i]}'
  ].join('\n');

  final system =
      'Você é um classificador de frases para um app de frases e status em '
      'português do Brasil. Para cada frase, escolha a categoria MAIS adequada '
      'usando SOMENTE os IDs da lista fornecida. Marque "prohibited": true '
      'somente para conteúdo realmente proibido em loja de apps: discurso de '
      'ódio, discriminação, violência explícita, conteúdo sexual explícito, '
      'incitação a crime ou drogas ilícitas. Frases ousadas/indiretas NÃO são '
      'proibidas. Responda EXCLUSIVAMENTE com um array JSON, sem texto extra.';

  final user = 'Categorias válidas (id: nome):\n$catList\n\n'
      'Frases (numeradas):\n$numbered\n\n'
      'Para cada frase retorne um objeto: '
      '{"i": <número>, "categoryId": "<id da lista>", '
      '"prohibited": <true|false>, "reason": "<curto, só se proibida>"}. '
      'Retorne o array JSON na mesma ordem.';

  final resp = await http.post(
    Uri.parse(_apiUrl),
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: jsonEncode({
      'model': _model,
      'max_tokens': 4096,
      'system': system,
      'messages': [
        {'role': 'user', 'content': user}
      ],
    }),
  );
  if (resp.statusCode != 200) {
    throw 'API ${resp.statusCode}: ${resp.body}';
  }
  final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
  final text = (data['content'] as List)
      .map((b) => (b is Map && b['type'] == 'text') ? b['text'] : '')
      .join();
  final arr = jsonDecode(_extractJsonArray(text)) as List;

  final out = <_Result>[];
  for (final item in arr) {
    if (item is! Map) continue;
    final idx = (item['i'] as num?)?.toInt();
    if (idx == null || idx < 1 || idx > phrases.length) continue;
    out.add(_Result(
      phrase: phrases[idx - 1],
      categoryId: (item['categoryId'] ?? '').toString().trim(),
      prohibited: item['prohibited'] == true,
      reason: (item['reason'] ?? '').toString(),
    ));
  }
  return out;
}

/// Extrai o primeiro array JSON do texto (caso o modelo cerque com prosa).
String _extractJsonArray(String text) {
  final start = text.indexOf('[');
  final end = text.lastIndexOf(']');
  if (start >= 0 && end > start) return text.substring(start, end + 1);
  return text;
}

class _Result {
  _Result({
    required this.phrase,
    required this.categoryId,
    required this.prohibited,
    required this.reason,
  });
  final String phrase;
  final String categoryId;
  final bool prohibited;
  final String reason;
}
