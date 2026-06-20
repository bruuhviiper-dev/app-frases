import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frases_status/data/card_style.dart';
import 'package:frases_status/data/models.dart';
import 'package:frases_status/widgets/shareable_card.dart';

void main() {
  testWidgets('ShareableCard não estoura (overflow) em nenhum formato',
      (tester) async {
    const longText =
        'Esta é uma frase bem longa para testar se o cartão se ajusta sem '
        'estourar o layout em formatos menores como o quadrado. Repetimos '
        'bastante texto de propósito para forçar o limite vertical e garantir '
        'que a tarja de overflow não apareça mais em nenhum formato do editor.';
    final phrase = Phrase(
      text: longText,
      categoryId: 'amor',
      categoryName: 'Amor',
      gradient: const [Color(0xFFFF5F6D), Color(0xFFFFC371)],
      author: 'Autor de Teste',
    );

    for (final format in CardFormat.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: ShareableCard(
                  phrase: phrase,
                  style: CardStyle(
                    background: const [Color(0xFF15151A)],
                    format: format,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull,
          reason: 'O formato ${format.label} estourou o layout (overflow).');
    }
  });
}
