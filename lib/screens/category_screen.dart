import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/content_repository.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/phrase_list_item.dart';
import 'feed_screen.dart';

/// Lista as frases de uma categoria, com atalho para o modo feed.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentRepository>();
    final category = content.categoryById(categoryId);
    final phrases = content.phrasesOf(categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text('${category.emoji} ${category.name}'),
        actions: [
          IconButton(
            tooltip: 'Modo feed',
            icon: const Icon(Icons.style_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  body: FeedScreen(categoryId: categoryId),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: phrases.length,
        itemBuilder: (context, i) => PhraseListItem(phrase: phrases[i]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(body: FeedScreen(categoryId: categoryId)),
          ),
        ),
        backgroundColor: category.gradient.first,
        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
        label: const Text('Modo feed',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
