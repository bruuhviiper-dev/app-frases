import 'package:flutter/material.dart';

/// Espaço RESERVADO para o banner de anúncio.
///
/// Mantém sempre a altura padrão de um banner (evita "pulo" no layout quando o
/// anúncio real carrega) e exibe um marcador de preview. É usado:
/// - no web/preview, onde não há AdMob;
/// - no mobile, enquanto o anúncio real ainda está carregando.
class BannerAdPlaceholder extends StatelessWidget {
  const BannerAdPlaceholder({super.key, this.height = 50});

  /// Altura do espaço reservado (igual à de `AdSize.banner`, 50dp).
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: Border(
            top: BorderSide(color: scheme.onSurface.withValues(alpha: 0.06)),
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined,
                size: 16, color: scheme.onSurface.withValues(alpha: 0.45)),
            const SizedBox(width: 8),
            Text(
              'Espaço de anúncio (preview)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
