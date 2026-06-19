import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/app_theme.dart';
import '../data/models.dart';
import '../services/ads_service.dart';
import '../services/app_state.dart';
import '../services/content_repository.dart';
import '../widgets/author_avatar.dart';
import '../widgets/pulse_heart.dart';
import '../widgets/rate_prompt.dart';
import '../widgets/share_helper.dart';
import 'card_preview_screen.dart';

/// Feed vertical estilo "Reels" de frases — clean, fundo branco. Deslize para
/// cima para a próxima. ILIMITADO: as frases reembaralham a cada volta.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, this.categoryId, this.phrases});

  /// Filtra por categoria. Ignorado quando [phrases] é informado.
  final String? categoryId;

  /// Lista explícita de frases (ex.: reproduzir Favoritas ou Histórico no
  /// modo feed). Quando nulo, usa categoria ou todas embaralhadas.
  final List<Phrase>? phrases;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final List<Phrase> _phrases;
  late final bool _shuffleOnLoop;
  final _controller = PageController();

  @override
  void initState() {
    super.initState();
    final content = context.read<ContentRepository>();
    if (widget.phrases != null) {
      _phrases = widget.phrases!;
      _shuffleOnLoop = false;
    } else if (widget.categoryId != null) {
      _phrases = content.phrasesOf(widget.categoryId!);
      _shuffleOnLoop = false;
    } else {
      _phrases = List.of(content.allPhrases)..shuffle();
      _shuffleOnLoop = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _onView(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onView(int index) {
    if (!mounted || _phrases.isEmpty) return;
    context.read<AppState>().registerView(_phrases[index % _phrases.length]);
    AdsService.instance.registerActionAndMaybeShow();
  }

  void _onPageChanged(int index) {
    _onView(index);
    if (_shuffleOnLoop && index % _phrases.length == 0 && index > 0) {
      _phrases.shuffle();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_phrases.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('Nada para mostrar aqui ainda.',
              textAlign: TextAlign.center),
        ),
      );
    }
    // Mostra o botão "voltar" só quando o feed foi aberto por cima de outra
    // tela (ex.: "Surpreenda-me", "Modo feed"). Na aba Feed não há para onde
    // voltar, então o botão não aparece.
    final canPop = Navigator.of(context).canPop();
    return PageView.builder(
      controller: _controller,
      scrollDirection: Axis.vertical,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, i) =>
          _FeedPage(phrase: _phrases[i % _phrases.length], showBack: canPop),
    );
  }
}

class _FeedPage extends StatelessWidget {
  const _FeedPage({required this.phrase, this.showBack = false});

  final Phrase phrase;

  /// Quando verdadeiro, exibe um botão de voltar no topo (feed empurrado).
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final fontSize = _adaptiveSize(phrase.text.length);
    final gradient = phrase.gradient.length >= 2
        ? phrase.gradient
        : AppTheme.redGradient;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppTheme.gradient(gradient)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (showBack) ...[
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(phrase.categoryName.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            fontSize: 13,
                          )),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.keyboard_arrow_up_rounded,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 16),
                      const SizedBox(width: 4),
                      Text('deslize',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.format_quote_rounded,
                            color: Colors.white.withValues(alpha: 0.92),
                            size: 52),
                        const SizedBox(height: 18),
                        Text(
                          phrase.text,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: fontSize,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (phrase.author != null) ...[
                          const SizedBox(height: 22),
                          AuthorAvatar(author: phrase.author!, size: 54),
                          const SizedBox(height: 10),
                          Text(phrase.author!,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              _FeedActions(phrase: phrase),
            ],
          ),
        ),
      ),
    );
  }

  double _adaptiveSize(int len) {
    if (len < 50) return 32;
    if (len < 100) return 28;
    if (len < 160) return 24;
    return 21;
  }
}

class _FeedActions extends StatelessWidget {
  const _FeedActions({required this.phrase});

  final Phrase phrase;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final fav = state.isFavorite(phrase.id);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: 'Curtir',
          active: fav,
          onTap: () {
            HapticFeedback.selectionClick();
            context.read<AppState>().toggleFavorite(phrase.id);
          },
          child: PulseHeart(
            active: fav,
            activeColor: Colors.white,
            inactiveColor: Colors.white,
          ),
        ),
        _ActionButton(
          icon: Icons.copy_rounded,
          label: 'Copiar',
          onTap: () async {
            HapticFeedback.lightImpact();
            await ShareHelper.copyText(phrase.shareText);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Frase copiada!')),
              );
            }
          },
        ),
        _ActionButton(
          icon: Icons.image_rounded,
          label: 'Status',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => CardPreviewScreen(phrase: phrase)),
          ),
        ),
        _ActionButton(
          icon: Icons.chat_rounded,
          label: 'WhatsApp',
          highlight: const Color(0xFF25D366),
          onTap: () {
            HapticFeedback.lightImpact();
            ShareHelper.shareToWhatsApp(phrase.shareText);
            context.read<AppState>().registerShared();
            RatePrompt.maybeShow(context);
          },
        ),
        _ActionButton(
          icon: Icons.share_rounded,
          label: 'Enviar',
          onTap: () {
            HapticFeedback.lightImpact();
            ShareHelper.shareText(phrase.shareText);
            context.read<AppState>().registerShared();
            RatePrompt.maybeShow(context);
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.highlight,
    this.child,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  /// Cor de destaque do botão (ex.: verde do WhatsApp).
  final Color? highlight;

  /// Conteúdo custom no lugar do ícone (ex.: coração animado).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: highlight ??
                    Colors.white.withValues(alpha: active ? 0.32 : 0.18),
                shape: BoxShape.circle,
              ),
              child: child ?? Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
