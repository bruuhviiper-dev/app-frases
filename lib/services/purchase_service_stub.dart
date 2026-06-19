import 'package:flutter/foundation.dart';

import 'store_products.dart';

/// Versão de PREVIEW (web/desktop): não há Google Play Billing, então as
/// compras são SIMULADAS para você navegar e ver a loja funcionando. No app
/// real (Android) entra a implementação de `purchase_service_mobile.dart`.
class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  void Function(String productId)? _onGrant;
  void Function(String productId)? _onSubGrant;
  bool get isAvailable => true;

  void onEntitlement(void Function(String productId) cb) => _onGrant = cb;
  void onSubscriptionGranted(void Function(String productId) cb) =>
      _onSubGrant = cb;
  // Sem loja real no preview: não há o que revalidar (no-op).
  void onSubscriptionsReconciled(void Function(Set<String> activeIds) cb) {}

  Future<void> init() async {}

  /// Sem loja real aqui: devolve o preço de exibição do catálogo.
  String priceOf(String productId) =>
      StoreProducts.byId(productId)?.fallbackPrice ?? '';

  Future<PurchaseResult> buy(String productId) async {
    // Simula o tempo de processamento e concede o item.
    await Future.delayed(const Duration(milliseconds: 600));
    if (StoreProducts.subscriptionIds.contains(productId)) {
      _onSubGrant?.call(productId);
    } else {
      _onGrant?.call(productId);
    }
    return PurchaseResult.success;
  }

  Future<void> restore() async {}
}
