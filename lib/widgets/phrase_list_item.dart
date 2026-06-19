import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/app_theme.dart';
import '../data/models.dart';
import '../screens/card_preview_screen.dart';
import '../services/ads_service.dart';
import '../services/app_state.dart';
import 'author_avatar.dart';
import 'pulse_heart.dart';
import 'rate_prompt.dart';
import 'share_helper.dart';

/// Item de lista com a frase, autor (se houver) e ações.
class PhraseListItem extends StatelessWidget {
  const PhraseListItem({super.key, required this.phrase});

  final Phrase phrase;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final fav = state.isFavorite(phrase.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 7),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 10, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (phrase.author != null)
              Row(
                children: [
                  AuthorAvatar(author: phrase.author!, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(phrase.author!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800)),
                        Text(phrase.categoryName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: scheme.onSurface.withValues(alpha: 0.45),
                            )),
                      ],
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.brandRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(phrase.categoryName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: scheme.onSurface.withValues(alpha: 0.45),
                      )),
                ],
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(phrase.text,
                  style: const TextStyle(fontSize: 16, height: 1.45)),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                InkResponse(
                  radius: 24,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<AppState>().toggleFavorite(phrase.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: PulseHeart(
                      active: fav,
                      size: 21,
                      inactiveColor: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                _IconAction(
                  icon: Icons.copy_rounded,
                  onTap: () async {
                    await ShareHelper.copyText(phrase.shareText);
                    AdsService.instance.registerActionAndMaybeShow();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Frase copiada!')),
                      );
                    }
                  },
                ),
                _IconAction(
                  icon: Icons.image_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => CardPreviewScreen(phrase: phrase)),
                    );
                    AdsService.instance.registerActionAndMaybeShow();
                  },
                ),
                const Spacer(),
                _IconAction(
                  icon: Icons.chat_rounded,
                  color: const Color(0xFF25D366),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ShareHelper.shareToWhatsApp(phrase.shareText);
                    context.read<AppState>().registerShared();
                    AdsService.instance.registerActionAndMaybeShow();
                    RatePrompt.maybeShow(context);
                  },
                ),
                _IconAction(
                  icon: Icons.share_rounded,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ShareHelper.shareText(phrase.shareText);
                    context.read<AppState>().registerShared();
                    AdsService.instance.registerActionAndMaybeShow();
                    RatePrompt.maybeShow(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 21),
      color: color,
      visualDensity: VisualDensity.compact,
    );
  }
}
