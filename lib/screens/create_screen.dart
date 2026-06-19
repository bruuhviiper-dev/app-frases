import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_theme.dart';
import '../data/models.dart';
import '../services/app_state.dart';
import '../widgets/share_helper.dart';
import 'card_preview_screen.dart';

/// Tela "Criar": o usuário escreve a própria frase, poema ou recado e
/// transforma em imagem para compartilhar. As criações ficam salvas.
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Phrase _phraseFrom(String text) => Phrase(
        text: text.trim(),
        categoryId: 'minhas',
        categoryName: 'Minha frase',
        gradient: AppTheme.shareGradients.first,
      );

  void _openEditor(String text) {
    if (text.trim().isEmpty) return;
    context.read<AppState>().addMyPhrase(text);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardPreviewScreen(phrase: _phraseFrom(text)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final mine = state.myPhrases;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Criar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppTheme.gradient(AppTheme.redGradient),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('Escreva a sua frase',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Frase, poema, recado ou indireta. Transforme em imagem e compartilhe.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13),
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _controller,
                      maxLines: 5,
                      minLines: 3,
                      maxLength: 600,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: AppTheme.ink),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Digite aqui...',
                        counterText: '',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.brandRed,
                        ),
                        onPressed: _controller.text.trim().isEmpty
                            ? null
                            : () => _openEditor(_controller.text),
                        icon: const Icon(Icons.image_rounded),
                        label: const Text('Gerar imagem'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (mine.isNotEmpty) ...[
            Text('Minhas frases',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final text in mine)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 6, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text,
                          style: const TextStyle(fontSize: 16, height: 1.45)),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Gerar imagem',
                            icon: const Icon(Icons.image_rounded, size: 21),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CardPreviewScreen(
                                    phrase: _phraseFrom(text)),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copiar',
                            icon: const Icon(Icons.copy_rounded, size: 21),
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              await ShareHelper.copyText(text);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Frase copiada!')),
                                );
                              }
                            },
                          ),
                          IconButton(
                            tooltip: 'Enviar',
                            icon: const Icon(Icons.share_rounded, size: 21),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => ShareHelper.shareText(text),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Excluir',
                            icon: Icon(Icons.delete_outline_rounded,
                                size: 21,
                                color:
                                    scheme.onSurface.withValues(alpha: 0.5)),
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                context.read<AppState>().removeMyPhrase(text),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Center(
                child: Column(
                  children: [
                    const Text('✍️', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('Suas criações aparecem aqui',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Escreva acima e toque em "Gerar imagem".',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color:
                              scheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
