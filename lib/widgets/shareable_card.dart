import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_theme.dart';
import '../data/card_style.dart';
import '../data/models.dart';

/// Cartão que vira imagem para compartilhar (status do WhatsApp, post do
/// Instagram, etc.). Totalmente configurável via [CardStyle]: formato, fonte,
/// tamanho, alinhamento, fundo e cor do texto.
class ShareableCard extends StatelessWidget {
  const ShareableCard({
    super.key,
    required this.phrase,
    required this.style,
  });

  final Phrase phrase;
  final CardStyle style;

  @override
  Widget build(BuildContext context) {
    final textColor = style.lightText ? Colors.white : const Color(0xFF15151A);
    final fontSize = _adaptive(phrase.text.length) * style.fontScale;
    final hasAuthor = style.showAuthor && phrase.author != null;

    final crossAxis = switch (style.align) {
      TextAlign.left => CrossAxisAlignment.start,
      TextAlign.right => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.center,
    };

    // Renderiza num tamanho de design fixo (largura 360) e escala para caber no
    // espaço disponível. Assim o cartão fica idêntico em qualquer aparelho/
    // resolução e o texto nunca "estoura" (corta) em telas pequenas.
    return AspectRatio(
      aspectRatio: style.format.ratio,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 360,
          height: 360 / style.format.ratio,
          child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: style.background.length >= 2
              ? AppTheme.gradient(style.background)
              : null,
          color:
              style.background.length < 2 ? style.background.first : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 44),
          child: Column(
            crossAxisAlignment: crossAxis,
            children: [
              const Spacer(),
              Text('“',
                  style: GoogleFonts.playfairDisplay(
                    color: textColor.withValues(alpha: 0.85),
                    fontSize: 84,
                    height: 0.7,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 6),
              Text(
                phrase.text,
                textAlign: style.align,
                style: style.font.style(
                  fontSize: fontSize,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              if (hasAuthor) ...[
                const SizedBox(height: 18),
                Text('— ${phrase.author}',
                    textAlign: style.align,
                    style: GoogleFonts.inter(
                      color: textColor.withValues(alpha: 0.92),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    )),
              ],
              const Spacer(),
              if (style.showWatermark)
                Row(
                  mainAxisAlignment: switch (style.align) {
                    TextAlign.left => MainAxisAlignment.start,
                    TextAlign.right => MainAxisAlignment.end,
                    _ => MainAxisAlignment.center,
                  },
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(Icons.format_quote_rounded,
                          color: textColor, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Text('Frases & Status',
                        style: GoogleFonts.inter(
                          color: textColor.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }

  double _adaptive(int len) {
    if (len < 50) return 30;
    if (len < 110) return 26;
    if (len < 180) return 22;
    if (len < 260) return 19;
    return 16;
  }
}
