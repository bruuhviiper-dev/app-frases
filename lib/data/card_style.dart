import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Formato (proporção) do cartão exportado.
enum CardFormat {
  story('Story', 9 / 16, '9:16'),
  square('Post', 1 / 1, '1:1'),
  portrait('Retrato', 4 / 5, '4:5');

  const CardFormat(this.label, this.ratio, this.hint);

  final String label;
  final double ratio;
  final String hint;
}

/// Fontes disponíveis no editor de imagem.
enum CardFont {
  playfair('Elegante'),
  lora('Serifada'),
  montserrat('Moderna'),
  poppins('Suave'),
  bebas('Impacto'),
  dancing('Manuscrita'),
  inter('Limpa');

  const CardFont(this.label);

  final String label;

  /// Constrói o [TextStyle] da fonte escolhida.
  TextStyle style({
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w600,
    double height = 1.4,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    switch (this) {
      case CardFont.playfair:
        return GoogleFonts.playfairDisplay(
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
            height: height,
            fontStyle: fontStyle);
      case CardFont.lora:
        return GoogleFonts.lora(
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
            height: height,
            fontStyle: fontStyle);
      case CardFont.montserrat:
        return GoogleFonts.montserrat(
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
            height: height,
            fontStyle: fontStyle);
      case CardFont.poppins:
        return GoogleFonts.poppins(
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
            height: height,
            fontStyle: fontStyle);
      case CardFont.bebas:
        return GoogleFonts.bebasNeue(
            fontSize: fontSize * 1.25,
            color: color,
            fontWeight: FontWeight.w400,
            height: height * 0.95,
            letterSpacing: 0.5,
            fontStyle: fontStyle);
      case CardFont.dancing:
        return GoogleFonts.dancingScript(
            fontSize: fontSize * 1.25,
            color: color,
            fontWeight: FontWeight.w700,
            height: height,
            fontStyle: fontStyle);
      case CardFont.inter:
        return GoogleFonts.inter(
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
            height: height,
            fontStyle: fontStyle);
    }
  }
}

/// Conjunto de opções escolhidas pelo usuário no editor de imagem.
class CardStyle {
  const CardStyle({
    required this.background,
    this.font = CardFont.playfair,
    this.format = CardFormat.story,
    this.align = TextAlign.center,
    this.fontScale = 1.0,
    this.showAuthor = true,
    this.showWatermark = true,
    this.lightText = true,
  });

  /// Cores do fundo. Uma cor = fundo sólido; duas+ = gradiente.
  final List<Color> background;
  final CardFont font;
  final CardFormat format;
  final TextAlign align;
  final double fontScale;
  final bool showAuthor;
  final bool showWatermark;

  /// Texto claro (branco) sobre fundo escuro; quando falso, texto escuro.
  final bool lightText;

  CardStyle copyWith({
    List<Color>? background,
    CardFont? font,
    CardFormat? format,
    TextAlign? align,
    double? fontScale,
    bool? showAuthor,
    bool? showWatermark,
    bool? lightText,
  }) {
    return CardStyle(
      background: background ?? this.background,
      font: font ?? this.font,
      format: format ?? this.format,
      align: align ?? this.align,
      fontScale: fontScale ?? this.fontScale,
      showAuthor: showAuthor ?? this.showAuthor,
      showWatermark: showWatermark ?? this.showWatermark,
      lightText: lightText ?? this.lightText,
    );
  }
}
