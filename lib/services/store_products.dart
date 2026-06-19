import 'package:flutter/material.dart';

import '../data/app_palettes.dart';

enum ProductKind { removeAds, watermark, styles, pack, theme, bundle, subscription }

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

  static const removeWatermark = StoreProduct(
    id: 'remove_watermark',
    kind: ProductKind.watermark,
    title: 'Remover marca d\'água',
    description: 'Compartilhe suas imagens sem a assinatura do app.',
    fallbackPrice: 'R\$ 3,90',
    emoji: '💧',
  );

  static const premiumStyles = StoreProduct(
    id: 'premium_styles',
    kind: ProductKind.styles,
    title: 'Estilos premium',
    description: 'Fontes exclusivas e fundos especiais para seus cartões.',
    fallbackPrice: 'R\$ 5,90',
    emoji: '🖌️',
  );

  static const packExclusivas = StoreProduct(
    id: 'pack_exclusivas',
    kind: ProductKind.pack,
    title: 'Pacote de frases exclusivas',
    description: 'Categorias premium liberadas só com este pacote.',
    fallbackPrice: 'R\$ 7,90',
    emoji: '🔒',
  );

  /// IDs das categorias que só ficam liberadas com [packExclusivas] (ou bundle).
  static const Set<String> exclusiveCategoryIds = {'exc_pesadas', 'exc_rica'};

  static const premiumBundle = StoreProduct(
    id: 'premium_bundle',
    kind: ProductKind.bundle,
    title: 'Premium (tudo)',
    description: 'Sem anúncios + TODOS os temas. A melhor oferta.',
    fallbackPrice: 'R\$ 19,90',
    emoji: '👑',
  );

  // ----- Assinaturas (recorrentes) -----
  static const premiumMonthly = StoreProduct(
    id: 'premium_monthly',
    kind: ProductKind.subscription,
    title: 'Premium mensal',
    description: 'Tudo liberado enquanto a assinatura estiver ativa.',
    fallbackPrice: 'R\$ 4,90/mês',
    emoji: '👑',
  );

  static const premiumYearly = StoreProduct(
    id: 'premium_yearly',
    kind: ProductKind.subscription,
    title: 'Premium anual',
    description: 'Todos os recursos o ano inteiro, com desconto.',
    fallbackPrice: 'R\$ 39,90/ano',
    emoji: '👑',
  );

  static List<StoreProduct> get subscriptions => [premiumMonthly, premiumYearly];

  /// IDs das assinaturas (recorrentes, revalidadas a cada abertura).
  static const Set<String> subscriptionIds = {
    'premium_monthly',
    'premium_yearly',
  };

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
  static List<StoreProduct> get all => [
        removeAds,
        removeWatermark,
        premiumStyles,
        packExclusivas,
        premiumBundle,
        premiumMonthly,
        premiumYearly,
        ...themes,
      ];

  static Set<String> get allIds => {for (final p in all) p.id};

  static StoreProduct? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static Color emojiTint(ProductKind kind) => switch (kind) {
        ProductKind.removeAds => const Color(0xFFEF4444),
        ProductKind.watermark => const Color(0xFF0EA5E9),
        ProductKind.styles => const Color(0xFFDB2777),
        ProductKind.pack => const Color(0xFF9333EA),
        ProductKind.subscription => const Color(0xFFD9A406),
        ProductKind.bundle => const Color(0xFFD9A406),
        ProductKind.theme => const Color(0xFF7C3AED),
      };
}
