import 'package:flutter/material.dart';

import '../data/app_palettes.dart';

enum ProductKind { removeAds, theme, bundle }

/// Resultado de uma tentativa de compra.
enum PurchaseResult { success, pending, cancelled, error, unavailable }

/// Um item à venda na loja (compra ÚNICA, não assinatura).
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.fallbackPrice,
    this.emoji = '✨',
    this.paletteId,
  });

  final String id;
  final ProductKind kind;
  final String title;
  final String description;

  /// Preço exibido se a Play Store não retornar o valor real (ex.: preview).
  final String fallbackPrice;
  final String emoji;

  /// Para temas: qual paleta este produto desbloqueia.
  final String? paletteId;
}

/// Catálogo. Os `id` DEVEM ser iguais aos produtos criados no Play Console
/// (Produtos no app → produtos gerenciados / compra única).
class StoreProducts {
  StoreProducts._();

  static const removeAds = StoreProduct(
    id: 'remove_ads',
    kind: ProductKind.removeAds,
    title: 'Remover anúncios',
    description: 'Adeus propaganda. Para sempre, com um pagamento único.',
    fallbackPrice: 'R\$ 8,90',
    emoji: '🚫',
  );

  static const premiumBundle = StoreProduct(
    id: 'premium_bundle',
    kind: ProductKind.bundle,
    title: 'Premium (tudo)',
    description: 'Sem anúncios + TODOS os temas. A melhor oferta.',
    fallbackPrice: 'R\$ 19,90',
    emoji: '👑',
  );

  /// Produtos de tema, gerados a partir das paletas premium.
  static final List<StoreProduct> themes = [
    for (final p in AppPalettes.all.where((p) => p.premium))
      StoreProduct(
        id: p.productId!,
        kind: ProductKind.theme,
        title: 'Tema ${p.name}',
        description: 'Deixe o app com a sua cara.',
        fallbackPrice: 'R\$ 4,90',
        emoji: '🎨',
        paletteId: p.id,
      ),
  ];

  /// Todos os produtos (para consultar preços reais na loja).
  static List<StoreProduct> get all =>
      [removeAds, premiumBundle, ...themes];

  static Set<String> get allIds => {for (final p in all) p.id};

  static StoreProduct? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static Color emojiTint(ProductKind kind) => switch (kind) {
        ProductKind.removeAds => const Color(0xFFEF4444),
        ProductKind.bundle => const Color(0xFFD9A406),
        ProductKind.theme => const Color(0xFF7C3AED),
      };
}
