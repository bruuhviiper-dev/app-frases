import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frases_status/screens/feed_screen.dart';
import 'package:frases_status/services/app_state.dart';
import 'package:frases_status/services/content_repository.dart';

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

  testWidgets('Feed empurrado mostra "voltar" e retorna para a home',
      (tester) async {
    await tester.pumpWidget(_wrap(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const Scaffold(body: FeedScreen())),
              ),
              child: const Text('Surpreenda-me'),
            ),
          ),
        ),
      ),
      state,
      content,
    ));
    await tester.pump();

    // Estamos na home; ainda não há botão de voltar do feed.
    expect(find.text('Surpreenda-me'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);

    // Abre o feed (rota empurrada).
    await tester.tap(find.text('Surpreenda-me'));
    await tester.pumpAndSettle();

    // O botão de voltar deve aparecer no feed empurrado.
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    // Tocar nele volta para a home.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Surpreenda-me'), findsOneWidget);
  });

  testWidgets('Feed como raiz (aba) não mostra botão de voltar',
      (tester) async {
    await tester.pumpWidget(
        _wrap(const Scaffold(body: FeedScreen()), state, content));
    await tester.pump();

    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });
}
