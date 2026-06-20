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
  playfair('Elegante', false),
  lora('Serifada', true),
  montserrat('Moderna', false),
  poppins('Suave', false),
  bebas('Impacto', true),
  dancing('Manuscrita', true),
  inter('Limpa', false);

  const CardFont(this.label, this.premium);

  final String label;

  /// Fonte exclusiva (requer "Estilos premium").
  final bool premium;

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
    this.watermarkText = 'Frases & Status',
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

  /// Texto da marca/assinatura no rodapé (premium pode personalizar).
  final String watermarkText;

  CardStyle copyWith({
    List<Color>? background,
    CardFont? font,
    CardFormat? format,
    TextAlign? align,
    double? fontScale,
    bool? showAuthor,
    bool? showWatermark,
    bool? lightText,
    String? watermarkText,
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
      watermarkText: watermarkText ?? this.watermarkText,
    );
  }
}

/// Modelo pronto de cartão (aplicado com 1 toque no editor).
class CardTemplate {
  const CardTemplate({
    required this.name,
    required this.background,
    this.font = CardFont.playfair,
    this.align = TextAlign.center,
    this.lightText = true,
    this.premium = false,
  });

  final String name;
  final List<Color> background;
  final CardFont font;
  final TextAlign align;
  final bool lightText;
  final bool premium;
}

/// Catálogo de modelos de cartão. Os marcados como [premium] exigem
/// "Estilos premium".
const cardTemplates = <CardTemplate>[
  CardTemplate(name: 'Clássico', background: [Color(0xFF15151A)]),
  CardTemplate(
      name: 'Pôr do sol',
      background: [Color(0xFFFF512F), Color(0xFFDD2476)],
      font: CardFont.montserrat),
  CardTemplate(
      name: 'Minimal',
      background: [Color(0xFFFFFFFF)],
      font: CardFont.inter,
      lightText: false),
  CardTemplate(
      name: 'Aurora',
      background: [Color(0xFF654EA3), Color(0xFFEAAFC8)],
      font: CardFont.poppins),
  CardTemplate(
      name: 'Ouro',
      background: [Color(0xFFFDC830), Color(0xFFF37335)],
      premium: true),
  CardTemplate(
      name: 'Impacto',
      background: [Color(0xFF000000), Color(0xFF434343)],
      font: CardFont.bebas,
      premium: true),
  CardTemplate(
      name: 'Romance',
      background: [Color(0xFFEE9CA7), Color(0xFFFFDDE1)],
      font: CardFont.dancing,
      lightText: false,
      premium: true),
  CardTemplate(
      name: 'Galáxia',
      background: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
      font: CardFont.lora,
      premium: true),
];
