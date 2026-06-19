import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/content_repository.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/phrase_list_item.dart';
import 'feed_screen.dart';

/// Frases curtidas pelo usuário.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final content = context.watch<ContentRepository>();
    final favorites =
        content.allPhrases.where((p) => state.isFavorite(p.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritas'),
        actions: [
          if (favorites.isNotEmpty)
            IconButton(
              tooltip: 'Reproduzir no feed',
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      Scaffold(body: FeedScreen(phrases: favorites)),
                ),
              ),
            ),
        ],
      ),
      body: favorites.isEmpty
          ? const _EmptyFavorites()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: favorites.length,
              itemBuilder: (context, i) =>
                  PhraseListItem(phrase: favorites[i]),
            ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💜', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Nenhuma frase favorita ainda',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Toque no coração das frases que você amar para guardá-las aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
