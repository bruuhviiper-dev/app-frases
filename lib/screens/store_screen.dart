import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_palettes.dart';
import '../data/app_theme.dart';
import '../services/app_state.dart';
import '../services/purchase_service.dart';
import '../services/store_products.dart';

/// Loja Premium: compra única para remover anúncios, comprar temas e o pacote
/// completo. Monetização sem assinatura.
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  Future<void> _buy(BuildContext context, String productId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abrindo a compra…')),
    );
    final res = await PurchaseService.instance.buy(productId);
    if (!context.mounted) return;
    final msg = switch (res) {
      PurchaseResult.success => 'Tudo certo! Item liberado. 🎉',
      PurchaseResult.pending => 'Confirme a compra na janela da loja…',
      PurchaseResult.cancelled => 'Compra cancelada.',
      PurchaseResult.unavailable =>
        'Produto indisponível. Tente novamente mais tarde.',
      PurchaseResult.error => 'Não foi possível concluir a compra.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loja Premium'),
        actions: [
          TextButton(
            onPressed: () async {
              await PurchaseService.instance.restore();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Compras restauradas.')),
                );
              }
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          if (state.isPremium)
            _PremiumBadge(bundle: state.hasBundle)
          else
            _BundleCard(
              price: PurchaseService.instance.priceOf(StoreProducts.premiumBundle.id),
              onBuy: () => _buy(context, StoreProducts.premiumBundle.id),
            ),
          const SizedBox(height: 18),
          if (!state.isPremium) ...[
            _SectionTitle('Sem anúncios'),
            _ProductTile(
              product: StoreProducts.removeAds,
              price:
                  PurchaseService.instance.priceOf(StoreProducts.removeAds.id),
              owned: state.ownsProduct(StoreProducts.removeAds.id),
              onBuy: () => _buy(context, StoreProducts.removeAds.id),
            ),
            const SizedBox(height: 18),
          ],
          _SectionTitle('Temas'),
          const SizedBox(height: 4),
          Text(
            'Toque para usar um tema que você já tem, ou compre para desbloquear.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              for (final p in AppPalettes.all)
                _ThemeCard(
                  palette: p,
                  owned: state.ownsPalette(p.id),
                  selected: state.palette.id == p.id,
                  price: p.productId == null
                      ? ''
                      : PurchaseService.instance.priceOf(p.productId!),
                  onUse: () => context.read<AppState>().setPalette(p.id),
                  onBuy: p.productId == null
                      ? null
                      : () => _buy(context, p.productId!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge({required this.bundle});
  final bool bundle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.gradient(const [Color(0xFFFDC830), Color(0xFFF37335)]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Text('👑', style: TextStyle(fontSize: 34)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bundle ? 'Você é Premium!' : 'Anúncios removidos!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                    bundle
                        ? 'Aproveite todos os temas e o app sem anúncios.'
                        : 'Compre temas abaixo para deixar com a sua cara.',
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BundleCard extends StatelessWidget {
  const _BundleCard({required this.price, required this.onBuy});
  final String price;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.gradient(const [Color(0xFFFDC830), Color(0xFFF37335)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF37335).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👑', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              const Text('Premium',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('MELHOR OFERTA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Sem anúncios + TODOS os temas, para sempre.',
              style: TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFC2410C),
              ),
              onPressed: onBuy,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('Comprar tudo  •  $price',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.price,
    required this.owned,
    required this.onBuy,
  });

  final StoreProduct product;
  final String price;
  final bool owned;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Text(product.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(product.description,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      )),
                ],
              ),
            ),
            const SizedBox(width: 8),
            owned
                ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                : FilledButton(onPressed: onBuy, child: Text(price)),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.palette,
    required this.owned,
    required this.selected,
    required this.price,
    required this.onUse,
    this.onBuy,
  });

  final AppPalette palette;
  final bool owned;
  final bool selected;
  final String price;
  final VoidCallback onUse;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: owned ? onUse : onBuy,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? palette.accent
                : scheme.onSurface.withValues(alpha: 0.08),
            width: selected ? 2.2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradient(palette.gradient),
                    shape: BoxShape.circle,
                  ),
                ),
                const Spacer(),
                if (!owned)
                  Icon(Icons.lock_rounded,
                      size: 18,
                      color: scheme.onSurface.withValues(alpha: 0.4)),
                if (selected)
                  Icon(Icons.check_circle_rounded,
                      size: 20, color: palette.accent),
              ],
            ),
            const Spacer(),
            Text(palette.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            if (!owned)
              Text(price,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.accent))
            else if (selected)
              Text('Em uso',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.5)))
            else
              Text('Tocar para usar',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary,
          )),
    );
  }
}
