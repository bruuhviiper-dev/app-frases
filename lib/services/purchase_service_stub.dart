import 'package:flutter/foundation.dart';

import 'store_products.dart';

/// Versão de PREVIEW (web/desktop): não há Google Play Billing, então as
/// compras são SIMULADAS para você navegar e ver a loja funcionando. No app
/// real (Android) entra a implementação de `purchase_service_mobile.dart`.
class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  void Function(String productId)? _onGrant;
  bool get isAvailable => true;

  void onEntitlement(void Function(String productId) cb) => _onGrant = cb;

  Future<void> init() async {}

  /// Sem loja real aqui: devolve o preço de exibição do catálogo.
  String priceOf(String productId) =>
      StoreProducts.byId(productId)?.fallbackPrice ?? '';

  Future<PurchaseResult> buy(String productId) async {
    // Simula o tempo de processamento e concede o item.
    await Future.delayed(const Duration(milliseconds: 600));
    _onGrant?.call(productId);
    return PurchaseResult.success;
  }

  Future<void> restore() async {}
}
