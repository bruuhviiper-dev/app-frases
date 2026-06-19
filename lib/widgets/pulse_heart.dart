import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Coração que dá um "pulso" sempre que vira favorito — o tipo de micro-animação
/// que faz a experiência parecer premium, como nos maiores apps do gênero.
///
/// É apenas visual: quem trata o toque (e o feedback tátil) é o widget pai.
class PulseHeart extends StatefulWidget {
  const PulseHeart({
    super.key,
    required this.active,
    this.size = 22,
    this.activeColor = const Color(0xFFFF1B3D),
    this.inactiveColor,
  });

  final bool active;
  final double size;
  final Color activeColor;
  final Color? inactiveColor;

  @override
  State<PulseHeart> createState() => _PulseHeartState();
}

class _PulseHeartState extends State<PulseHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void didUpdateWidget(covariant PulseHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Anima só ao favoritar (não ao desfavoritar).
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inactive = widget.inactiveColor ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Pulso: cresce até ~1.35x no meio e volta a 1.0.
        final scale = 1 + math.sin(_controller.value * math.pi) * 0.35;
        return Transform.scale(scale: scale, child: child);
      },
      child: Icon(
        widget.active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: widget.active ? widget.activeColor : inactive,
        size: widget.size,
      ),
    );
  }
}
