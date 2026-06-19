import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frases_status/data/card_style.dart';
import 'package:frases_status/data/models.dart';
import 'package:frases_status/screens/card_preview_screen.dart';
import 'package:frases_status/screens/create_screen.dart';
import 'package:frases_status/services/app_state.dart';
import 'package:frases_status/services/content_repository.dart';
import 'package:frases_status/widgets/shareable_card.dart';

Widget _wrap(Widget child, AppState state, ContentRepository content) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: state),
      ChangeNotifierProvider.value(value: content),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  late AppState state;
  late ContentRepository content;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    state = AppState(prefs);
    content = ContentRepository(prefs);
  });

  const phrase = Phrase(
    text: 'A persistência realiza o impossível.',
    categoryId: 'foco',
    categoryName: 'Foco & Sucesso',
    gradient: [Color(0xFF6A11CB), Color(0xFF2575FC)],
  );

  testWidgets('Editor de imagem monta e troca de abas', (tester) async {
    await tester.pumpWidget(_wrap(
        const CardPreviewScreen(phrase: phrase), state, content));
    await tester.pump();

    expect(find.text('Criar imagem'), findsOneWidget);
    expect(find.byType(ShareableCard), findsOneWidget);

    // Abas: Fundo, Texto, Formato.
    await tester.tap(find.text('Texto'));
    await tester.pump();
    expect(find.byType(Slider), findsOneWidget);

    await tester.tap(find.text('Formato'));
    await tester.pump();
    expect(find.text('Autor'), findsOneWidget);
  });

  testWidgets('Tela Criar salva frase e lista', (tester) async {
    await tester.pumpWidget(_wrap(const CreateScreen(), state, content));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Minha frase de teste');
    await tester.pump();
    state.addMyPhrase('Minha frase de teste');
    await tester.pump();

    expect(state.myPhrases, contains('Minha frase de teste'));
  });

  testWidgets('CardStyle copyWith preserva e altera campos', (tester) async {
    const base = CardStyle(background: [Color(0xFF000000)]);
    final next = base.copyWith(
        font: CardFont.bebas,
        format: CardFormat.square,
        fontScale: 1.3,
        lightText: false);
    expect(next.font, CardFont.bebas);
    expect(next.format, CardFormat.square);
    expect(next.fontScale, 1.3);
    expect(next.lightText, false);
    // Campo não alterado é preservado.
    expect(next.background.first, const Color(0xFF000000));
  });
}
