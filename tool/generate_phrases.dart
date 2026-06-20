// Gerador em massa de frases ORIGINAIS com IA (API do Claude / Anthropic).
//
// Cria frases novas por categoria, em português do Brasil, prontas para
// compartilhar — com deduplicação e sem conteúdo proibido. Pensado para montar
// um acervo grande (ex.: 20 mil) que será publicado como CONTEÚDO REMOTO
// (o app baixa e mescla via ContentRepository, sem inchar o APK).
//
// É RESUMÍVEL: se interromper, rode de novo que ele continua de onde parou
// (lê o que já gerou em content/generated_phrases.json).
//
// USO:
//   $env:ANTHROPIC_API_KEY = "sk-ant-..."        # PowerShell
//   dart run tool/generate_phrases.dart 250      # 250 frases por categoria
//
// Saídas:
//   content/generated_phrases.json   -> formato remoto (publique este arquivo)
//   content/existing_phrases.txt     -> base de dedup (atualizada a cada run)

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _apiUrl = 'https://api.anthropic.com/v1/messages';
const _model = 'claude-haiku-4-5-20251001';
const _askPerCall = 40; // quantas frases pedir por requisição

// Categorias de CITAÇÕES/autores: NÃO geramos "frases originais" aqui (seriam
// citações falsas atribuídas a pessoas reais). Pule-as.
const _skip = {
  'pensadores', 'proverbios', 'versiculos', 'poemas', 'filosofos',
  'genios_ciencia', 'visionarios', 'ingles',
};

Future<void> main(List<String> args) async {
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('ERRO: defina ANTHROPIC_API_KEY no ambiente.');
    exit(1);
  }
  final perCategory = args.isNotEmpty ? int.tryParse(args.first) ?? 250 : 250;

  final catFile = File('tool/categories.json');
  if (!catFile.existsSync()) {
    stderr.writeln('ERRO: tool/categories.json não encontrado.');
    exit(1);
  }
  final catalog = <String, String>{};
  for (final c in jsonDecode(catFile.readAsStringSync()) as List) {
    final id = c['id'].toString();
    if (!_skip.contains(id)) catalog[id] = c['name'].toString();
  }

  // Dedup global + estado resumível.
  final allNorm = <String>{};
  final byCat = <String, List<String>>{};

  // Carrega frases já existentes (para não repetir o acervo atual).
  final existingFile = File('content/existing_phrases.txt');
  if (existingFile.existsSync()) {
    for (final l in existingFile.readAsLinesSync()) {
      final n = _norm(l);
      if (n.isNotEmpty) allNorm.add(n);
    }
  }
  // Retoma o que já foi gerado.
  final outFile = File('content/generated_phrases.json');
  if (outFile.existsSync()) {
    try {
      final prev = jsonDecode(outFile.readAsStringSync()) as Map;
      for (final c in (prev['categories'] as List)) {
        final id = c['id'].toString();
        final list = (c['phrases'] as List).map((e) => e.toString()).toList();
        byCat[id] = list;
        for (final p in list) allNorm.add(_norm(p));
      }
      stdout.writeln('Retomando: já havia ${allNorm.length} frases.');
    } catch (_) {}
  }

  var totalNew = 0;
  for (final entry in catalog.entries) {
    final id = entry.key;
    final name = entry.value;
    final list = byCat.putIfAbsent(id, () => []);
    if (list.length >= perCategory) continue;

    var stagnant = 0;
    while (list.length < perCategory && stagnant < 3) {
      final need = perCategory - list.length;
      final ask = need < _askPerCall ? need : _askPerCall;
      List<String> got;
      try {
        got = await _generate(apiKey, name, ask);
      } catch (e) {
        stderr.writeln('  [$id] erro: $e');
        stagnant++;
        continue;
      }
      var added = 0;
      for (final p in got) {
        final t = p.trim();
        if (t.isEmpty) continue;
        final n = _norm(t);
        if (allNorm.contains(n)) continue;
        allNorm.add(n);
        list.add(t);
        added++;
      }
      totalNew += added;
      if (added == 0) {
        stagnant++;
      } else {
        stagnant = 0;
      }
      stdout.writeln('  [$id] ${list.length}/$perCategory (+$added)');
      _save(outFile, catalog, byCat); // salva a cada lote (resumível)
    }
  }

  // Atualiza a base de dedup com tudo.
  final sb = StringBuffer();
  for (final l in byCat.values) {
    for (final p in l) {
      sb.writeln(p);
    }
  }
  existingFile.createSync(recursive: true);
  // anexa (mantém o que já havia)
  existingFile.writeAsStringSync(sb.toString(), mode: FileMode.append);

  final total = byCat.values.fold<int>(0, (s, l) => s + l.length);
  stdout.writeln('\n==== PRONTO ====');
  stdout.writeln('Novas nesta execução: $totalNew');
  stdout.writeln('Total no arquivo: $total frases em ${byCat.length} categorias');
  stdout.writeln('Arquivo: content/generated_phrases.json');
}

void _save(File f, Map<String, String> catalog, Map<String, List<String>> byCat) {
  final cats = [
    for (final e in byCat.entries)
      if (e.value.isNotEmpty)
        {'id': e.key, 'name': catalog[e.key], 'phrases': e.value}
  ];
  f.createSync(recursive: true);
  f.writeAsStringSync(jsonEncode({
    'version': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'categories': cats,
  }));
}

String _norm(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

Future<List<String>> _generate(String apiKey, String categoryName, int n) async {
  final system =
      'Você escreve frases ORIGINAIS para um app de frases e status em '
      'português do Brasil. Frases curtas a médias, variadas em estrutura e '
      'tema, prontas para compartilhar (WhatsApp/Instagram). Nada de clichês '
      'repetidos, nada de conteúdo proibido (ódio, discriminação, sexual/'
      'violência explícita, ilegal). Não numere, não comente. Responda APENAS '
      'com um array JSON de strings.';
  final user =
      'Gere $n frases ORIGINAIS e DIFERENTES entre si para a categoria '
      '"$categoryName". Variadas e criativas. Responda só com o array JSON.';

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
      'temperature': 1.0,
      'system': system,
      'messages': [
        {'role': 'user', 'content': user}
      ],
    }),
  );
  if (resp.statusCode != 200) throw 'API ${resp.statusCode}: ${resp.body}';
  final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
  final text = (data['content'] as List)
      .map((b) => (b is Map && b['type'] == 'text') ? b['text'] : '')
      .join();
  final start = text.indexOf('[');
  final end = text.lastIndexOf(']');
  if (start < 0 || end <= start) return const [];
  final arr = jsonDecode(text.substring(start, end + 1)) as List;
  return arr.map((e) => e.toString()).toList();
}
