import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../services/app_state.dart';
import '../services/content_repository.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/phrase_list_item.dart';
import 'feed_screen.dart';

/// Vistas recentes: as últimas frases que o usuário viu no app. Ajuda a
/// reencontrar aquela frase que passou no feed e não deu tempo de salvar.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  /// Reconstrói uma [Phrase] completa a partir do histórico, recuperando o
  /// gradiente pela categoria de origem.
  List<Phrase> _phrasesFrom(
      List<ViewedPhrase> history, ContentRepository content) {
    return [
      for (final v in history)
        Phrase(
          text: v.text,
          categoryId: v.categoryId,
          categoryName: v.categoryName,
          gradient: content.categoryById(v.categoryId).gradient,
          author: v.author,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final content = context.watch<ContentRepository>();
    final phrases = _phrasesFrom(state.history, content);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vistas recentes'),
        actions: [
          if (phrases.isNotEmpty) ...[
            IconButton(
              tooltip: 'Reproduzir no feed',
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(body: FeedScreen(phrases: phrases)),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Limpar histórico',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () => _confirmClear(context),
            ),
          ],
        ],
      ),
      body: phrases.isEmpty
          ? const _EmptyHistory()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: phrases.length,
              itemBuilder: (context, i) => PhraseListItem(phrase: phrases[i]),
            ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: const Text('As vistas recentes serão apagadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AppState>().clearHistory();
    }
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🕘', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Nenhuma frase vista ainda',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'As frases que você abrir no feed aparecem aqui para você '
              'reencontrar depois.',
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
