import 'package:flutter/material.dart';

/// Uma paleta de cores vendável na loja (tema do app).
///
/// O tema "clássico" é grátis; os demais são desbloqueados por compra única
/// (via [productId]) ou pelo pacote premium.
class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.accent,
    required this.gradient,
    this.premium = true,
    this.productId,
  });

  final String id;
  final String name;

  /// Cor de destaque (botões, navegação, realces).
  final Color accent;

  /// Gradiente da marca usado nos cartões/heros.
  final List<Color> gradient;

  /// Falso só para o tema grátis padrão.
  final bool premium;

  /// ID do produto na Play Store que desbloqueia este tema (null = grátis).
  final String? productId;
}

/// Catálogo de paletas. A primeira é a grátis (padrão).
class AppPalettes {
  AppPalettes._();

  static const classico = AppPalette(
    id: 'classico',
    name: 'Clássico',
    accent: Color(0xFFFF1B3D),
    gradient: [Color(0xFFFF1B3D), Color(0xFFD1002E)],
    premium: false,
  );

  static const all = <AppPalette>[
    classico,
    AppPalette(
      id: 'roxo',
      name: 'Roxo Real',
      accent: Color(0xFF7C3AED),
      gradient: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      productId: 'theme_roxo',
    ),
    AppPalette(
      id: 'oceano',
      name: 'Oceano',
      accent: Color(0xFF0EA5E9),
      gradient: [Color(0xFF2193B0), Color(0xFF6DD5ED)],
      productId: 'theme_oceano',
    ),
    AppPalette(
      id: 'sunset',
      name: 'Pôr do Sol',
      accent: Color(0xFFFB7185),
      gradient: [Color(0xFFFF512F), Color(0xFFDD2476)],
      productId: 'theme_sunset',
    ),
    AppPalette(
      id: 'esmeralda',
      name: 'Esmeralda',
      accent: Color(0xFF10B981),
      gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
      productId: 'theme_esmeralda',
    ),
    AppPalette(
      id: 'dourado',
      name: 'Ouro',
      accent: Color(0xFFD9A406),
      gradient: [Color(0xFFFDC830), Color(0xFFF37335)],
      productId: 'theme_dourado',
    ),
    AppPalette(
      id: 'meianoite',
      name: 'Meia-Noite',
      accent: Color(0xFF6366F1),
      gradient: [Color(0xFF141E30), Color(0xFF243B55)],
      productId: 'theme_meianoite',
    ),
    AppPalette(
      id: 'rosa',
      name: 'Rosa Choque',
      accent: Color(0xFFEC4899),
      gradient: [Color(0xFFF857A6), Color(0xFFFF5858)],
      productId: 'theme_rosa',
    ),
    AppPalette(
      id: 'coral',
      name: 'Coral',
      accent: Color(0xFFFB7185),
      gradient: [Color(0xFFFF9966), Color(0xFFFF5E62)],
      productId: 'theme_coral',
    ),
    AppPalette(
      id: 'lavanda',
      name: 'Lavanda',
      accent: Color(0xFFA78BFA),
      gradient: [Color(0xFF654EA3), Color(0xFFEAAFC8)],
      productId: 'theme_lavanda',
    ),
    AppPalette(
      id: 'grafite',
      name: 'Grafite',
      accent: Color(0xFF94A3B8),
      gradient: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
      productId: 'theme_grafite',
    ),
    AppPalette(
      id: 'turquesa',
      name: 'Turquesa',
      accent: Color(0xFF14B8A6),
      gradient: [Color(0xFF1CD8D2), Color(0xFF16A085)],
      productId: 'theme_turquesa',
    ),
    AppPalette(
      id: 'vinho',
      name: 'Vinho',
      accent: Color(0xFFBE123C),
      gradient: [Color(0xFF42275A), Color(0xFF734B6D)],
      productId: 'theme_vinho',
    ),
  ];

  static AppPalette byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => classico);
}
