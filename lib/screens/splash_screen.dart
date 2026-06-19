import 'package:flutter/material.dart';

import '../data/app_theme.dart';

/// Abertura animada da marca — primeira impressão premium antes do conteúdo.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    final fade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration:
            BoxDecoration(gradient: AppTheme.gradient(AppTheme.redGradient)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: scale,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.format_quote_rounded,
                      color: AppTheme.brandRed, size: 64),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: fade,
                child: const Text(
                  'Frases & Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: fade,
                child: Text(
                  'sua frase certa, todo dia',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
