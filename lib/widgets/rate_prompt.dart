import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_theme.dart';
import '../services/app_state.dart';

/// Convite de avaliação exibido no momento certo: depois de o usuário já ter
/// compartilhado algumas frases (sinal de que está gostando). Mostrado uma
/// única vez. Padrão dos maiores apps para conquistar boas notas na loja.
class RatePrompt {
  RatePrompt._();

  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.frasesstatus.frases_status';

  /// Mostra o convite se for a hora certa. Seguro chamar após qualquer
  /// compartilhamento.
  static Future<void> maybeShow(BuildContext context) async {
    final state = context.read<AppState>();
    if (!state.shouldAskRate) return;
    state.markRatePromptDone(); // não pergunta de novo

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('Curtindo o app? '),
            Text('💜'),
          ],
        ),
        content: const Text(
          'Sua avaliação ajuda muito e leva só 10 segundos. '
          'Que nota você daria pra gente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Agora não'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              launchUrl(Uri.parse(_storeUrl),
                  mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.star_rounded, color: Colors.white, size: 18),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.brandRed),
            label: const Text('Avaliar'),
          ),
        ],
      ),
    );
  }
}
