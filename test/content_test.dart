import 'package:flutter_test/flutter_test.dart';

import 'package:frases_status/data/phrases.dart';
import 'package:frases_status/data/phrases_extra.dart';

/// Garante a integridade do banco de frases (semente + expansão).
void main() {
  final cats = PhraseData.bundled;

  test('Todas as categorias têm id, nome, emoji e >= 2 cores de gradiente', () {
    for (final c in cats) {
      expect(c.id.trim(), isNotEmpty, reason: 'id vazio em ${c.name}');
      expect(c.name.trim(), isNotEmpty, reason: 'nome vazio em ${c.id}');
      expect(c.emoji.trim(), isNotEmpty, reason: 'emoji vazio em ${c.id}');
      expect(c.gradient.length, greaterThanOrEqualTo(2),
          reason: 'gradiente curto em ${c.id}');
    }
  });

  test('IDs de categoria são únicos', () {
    final ids = cats.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'há IDs duplicados');
  });

  test('Nenhuma frase vazia e sem duplicatas dentro da mesma categoria', () {
    for (final c in cats) {
      final seen = <String>{};
      for (final p in c.phrases) {
        expect(p.trim(), isNotEmpty, reason: 'frase vazia em ${c.id}');
        final key = p.trim().toLowerCase();
        expect(seen.add(key), isTrue,
            reason: 'frase duplicada em ${c.id}: "$p"');
      }
    }
  });

  test('Listas de autores, quando existem, acompanham as frases', () {
    for (final c in cats) {
      final a = c.authors;
      if (a == null) continue;
      expect(a.length, c.phrases.length,
          reason: 'autores desalinhados em ${c.id}');
    }
  });

  test('A expansão realmente aumentou o acervo (sanidade)', () {
    final total = cats.fold<int>(0, (s, c) => s + c.phrases.length);
    // Antes da expansão eram ~708 frases; garantimos crescimento real.
    expect(total, greaterThan(900),
        reason: 'esperado acervo expandido, veio $total');
    expect(cats.length, greaterThanOrEqualTo(40),
        reason: 'esperado >= 40 categorias, veio ${cats.length}');
  });

  test('Categorias novas de PhraseExtra estão presentes no banco', () {
    final ids = cats.map((c) => c.id).toSet();
    for (final nc in PhraseExtra.newCategories) {
      expect(ids, contains(nc.id), reason: 'faltou a categoria ${nc.id}');
    }
  });
}
