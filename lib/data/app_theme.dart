import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de design e construção de temas do app.
///
/// Identidade: visual CLEAN em branco com vermelho vibrante de marca.
class AppTheme {
  AppTheme._();

  /// Vermelho vibrante da marca.
  static const Color brandRed = Color(0xFFFF1B3D);
  static const Color brandRedDark = Color(0xFFD1002E);

  static const Color seed = brandRed;

  // Claro (padrão) — base branca, bem limpa.
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF6F6F8);
  static const Color ink = Color(0xFF15151A);

  // Escuro.
  static const Color darkBackground = Color(0xFF101014);
  static const Color darkSurface = Color(0xFF17171D);
  static const Color darkSurfaceHigh = Color(0xFF20202A);

  /// Gradiente da marca (vermelho vibrante), usado em destaques.
  static const List<Color> redGradient = [brandRed, brandRedDark];

  /// Fundos disponíveis para o cartão compartilhável (status).
  static const List<List<Color>> shareGradients = [
    [brandRed, brandRedDark],
    [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    [Color(0xFF000428), Color(0xFF004E92)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFFF512F), Color(0xFFDD2476)],
    [Color(0xFF2193B0), Color(0xFF6DD5ED)],
    [Color(0xFFf12711), Color(0xFFf5af19)],
    [Color(0xFF42275A), Color(0xFF734B6D)],
    [Color(0xFF1F1C2C), Color(0xFF928DAB)],
    [Color(0xFF0F2027), Color(0xFF2C5364)],
    [Color(0xFF654ea3), Color(0xFFeaafc8)],
    [Color(0xFF141E30), Color(0xFF243B55)],
    [Color(0xFFFF416C), Color(0xFFFF4B2B)],
    [Color(0xFF6A11CB), Color(0xFF2575FC)],
    [Color(0xFF00b09b), Color(0xFF96c93d)],
    [Color(0xFFEE0979), Color(0xFFFF6A00)],
  ];

  /// Fundos sólidos (uma cor) para o cartão compartilhável.
  static const List<Color> shareSolids = [
    Color(0xFF15151A), // preto suave
    Color(0xFFFFFFFF), // branco
    brandRed,
    Color(0xFF1B3A4B), // petróleo
    Color(0xFF2D2A32), // grafite
    Color(0xFFF5E6CA), // creme
    Color(0xFFE8505B), // coral
    Color(0xFF3D5A80), // azul ardósia
    Color(0xFF6D597A), // ameixa
    Color(0xFF283618), // verde musgo
    Color(0xFFFFB4A2), // pêssego
    Color(0xFF0D1B2A), // azul noite
  ];

  /// Fundos EXCLUSIVOS (requerem "Estilos premium"). Inclui combinações de
  /// 3 cores e tons especiais que se destacam dos fundos gratuitos.
  static const List<List<Color>> premiumShareGradients = [
    [Color(0xFFFDC830), Color(0xFFF37335)], // ouro
    [Color(0xFF7F00FF), Color(0xFFE100FF)], // uva
    [Color(0xFF00C9FF), Color(0xFF92FE9D)], // aqua menta
    [Color(0xFFf953c6), Color(0xFFb91d73)], // magenta
    [Color(0xFF3a1c71), Color(0xFFd76d77), Color(0xFFffaf7b)], // pôr do sol
    [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)], // galáxia
    [Color(0xFF000000), Color(0xFF434343)], // carvão
    [Color(0xFFffd89b), Color(0xFF19547b)], // areia e mar
  ];

  static LinearGradient gradient(List<Color> colors,
          {Alignment begin = Alignment.topLeft,
          Alignment end = Alignment.bottomRight}) =>
      LinearGradient(begin: begin, end: end, colors: colors);

  static List<BoxShadow> softShadow(Brightness b, {Color? tint}) => [
        BoxShadow(
          color: b == Brightness.dark
              ? Colors.black.withValues(alpha: 0.45)
              : (tint ?? brandRed).withValues(alpha: 0.18),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ];

  static ThemeData dark({Color accent = brandRed}) =>
      _build(Brightness.dark, accent);
  static ThemeData light({Color accent = brandRed}) =>
      _build(Brightness.light, accent);

  static ThemeData _build(Brightness brightness, Color accent) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      surface: isDark ? darkSurface : lightSurface,
      surfaceContainerHighest: isDark ? darkSurfaceHigh : lightSurfaceAlt,
      onSurface: isDark ? Colors.white : ink,
    );

    final base = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );
    final textTheme = base.copyWith(
      headlineLarge: base.headlineLarge
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
      headlineMedium: base.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6),
      headlineSmall: base.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
      titleLarge: base.titleLarge
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
    );

    final bg = isDark ? darkBackground : lightBackground;
    final surface = isDark ? darkSurfaceHigh : lightSurface;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: isDark ? darkSurface : lightSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final sel = s.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
            color: sel ? accent : scheme.onSurface.withValues(alpha: 0.55),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final sel = s.contains(WidgetState.selected);
          return IconThemeData(
            color: sel ? accent : scheme.onSurface.withValues(alpha: 0.5),
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle:
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle:
            GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? darkSurface : lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.onSurface.withValues(alpha: 0.07),
      ),
    );
  }
}
