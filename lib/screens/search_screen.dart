import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../data/models.dart';
import '../services/content_repository.dart';
import '../widgets/phrase_list_item.dart';

/// Busca por palavra em todas as frases do app.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Phrase> _all = const [];
  List<Phrase> _results = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _all = context.read<ContentRepository>().allPhrases;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _results = q.isEmpty
          ? const []
          : _all
              .where((p) =>
                  p.text.toLowerCase().contains(q) ||
                  p.categoryName.toLowerCase().contains(q) ||
                  (p.author?.toLowerCase().contains(q) ?? false))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Buscar frase ou categoria…',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _controller.clear();
                _onChanged('');
              },
            ),
        ],
      ),
      body: _controller.text.isEmpty
          ? const _Hint()
          : _results.isEmpty
              ? const Center(child: Text('Nenhuma frase encontrada.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _results.length,
                  itemBuilder: (context, i) =>
                      PhraseListItem(phrase: _results[i]),
                ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_rounded, size: 56),
            const SizedBox(height: 12),
            Text('Procure por uma palavra',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Ex.: amor, bom dia, fé, sextou…',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                )),
          ],
        ),
      ),
    );
  }
}
