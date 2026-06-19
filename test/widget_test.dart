import 'package:flutter_test/flutter_test.dart';

import 'package:frases_status/data/models.dart';
import 'package:frases_status/data/phrases.dart';

void main() {
  group('Conteúdo embutido', () {
    test('possui muitas categorias e frases', () {
      expect(PhraseData.bundled.length, greaterThanOrEqualTo(35));
      expect(PhraseData.allPhrases.length, greaterThan(700));
    });

    test('categorias com autor têm listas alinhadas', () {
      for (final c in PhraseData.bundled) {
        if (c.authors != null) {
          expect(c.authors!.length, c.phrases.length,
              reason: 'autores desalinhados em ${c.id}');
        }
      }
    });

    test('não há frases duplicadas dentro da mesma categoria', () {
      for (final c in PhraseData.bundled) {
        final set = c.phrases.map((e) => e.toLowerCase().trim()).toSet();
        expect(set.length, c.phrases.length, reason: 'Duplicata em ${c.id}');
      }
    });

    test('ids de categoria são únicos', () {
      final ids = PhraseData.bundled.map((c) => c.id).toSet();
      expect(ids.length, PhraseData.bundled.length);
    });

    test('cada frase gera um id único (favoritos)', () {
      final ids = PhraseData.allPhrases.map((p) => p.id).toSet();
      expect(ids.length, PhraseData.allPhrases.length);
    });

    test('phrasesOf retorna apenas frases da categoria pedida', () {
      final amor = PhraseData.phrasesOf('amor');
      expect(amor, isNotEmpty);
      expect(amor.every((p) => p.categoryId == 'amor'), true);
    });
  });

  group('Parsing de conteúdo remoto', () {
    test('PhraseCategory.fromJson interpreta gradiente hex e frases', () {
      final c = PhraseCategory.fromJson({
        'id': 'teste',
        'name': 'Teste',
        'emoji': '🧪',
        'gradient': ['#FF0000', '#0000FF'],
        'phrases': ['Frase A', 'Frase B', '   ', '']
      });
      expect(c, isNotNull);
      expect(c!.gradient.length, 2);
      expect(c.phrases, ['Frase A', 'Frase B']); // vazias removidas
    });

    test('fromJson devolve null sem id/name', () {
      expect(PhraseCategory.fromJson({'name': 'X'}), isNull);
    });
  });

  group('Mesclagem (auto-atualização)', () {
    test('merge adiciona novas sem duplicar', () {
      const c = PhraseCategory(
        id: 'x',
        name: 'X',
        emoji: '✨',
        gradient: [],
        phrases: ['um', 'dois'],
      );
      final merged = c.merge(['dois', 'três'], const [null, null]);
      expect(merged.phrases, ['um', 'dois', 'três']);
    });

    test('merge preserva e completa o autor', () {
      const c = PhraseCategory(
        id: 'x',
        name: 'X',
        emoji: '✨',
        gradient: [],
        phrases: ['frase sem autor'],
      );
      final merged = c.merge(['frase sem autor', 'nova'], ['Autor X', 'Autor Y']);
      expect(merged.phrases.length, 2);
      expect(merged.authorAt(0), 'Autor X'); // autor completado
      expect(merged.authorAt(1), 'Autor Y');
    });

    test('flatten propaga autor para Phrase', () {
      const c = PhraseCategory(
        id: 'q',
        name: 'Q',
        emoji: '📜',
        gradient: [],
        phrases: ['Só sei que nada sei.'],
        authors: ['Sócrates'],
      );
      final flat = PhraseData.flatten([c]);
      expect(flat.first.author, 'Sócrates');
      expect(flat.first.shareText, contains('— Sócrates'));
    });
  });
}
