import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/app_theme.dart';
import '../data/models.dart';

/// O cartão visual de uma frase, com gradiente de marca.
///
/// Quando [captureKey] é informado, o conteúdo "puro" (sem botões) é envolvido
/// por um RepaintBoundary para poder ser exportado como imagem.
class PhraseCard extends StatelessWidget {
  const PhraseCard({
    super.key,
    required this.phrase,
    this.captureKey,
    this.compact = false,
  });

  final Phrase phrase;
  final GlobalKey? captureKey;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final card = _CardContent(phrase: phrase, compact: compact);
    if (captureKey == null) return card;
    return RepaintBoundary(key: captureKey, child: card);
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.phrase, required this.compact});

  final Phrase phrase;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 22.0 : _adaptiveFontSize(phrase.text.length);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 24 : 32, vertical: compact ? 28 : 40),
      decoration: BoxDecoration(
        gradient: AppTheme.gradient(phrase.gradient),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(phrase.categoryName.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  )),
            ],
          ),
          SizedBox(height: compact ? 14 : 24),
          Text(
            phrase.text,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (phrase.author != null) ...[
            SizedBox(height: compact ? 8 : 14),
            Text('— ${phrase.author}',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: compact ? 14 : 16,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                )),
          ],
          SizedBox(height: compact ? 14 : 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Frases & Status',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  double _adaptiveFontSize(int length) {
    if (length < 60) return 30;
    if (length < 110) return 26;
    if (length < 160) return 23;
    return 20;
  }
}
