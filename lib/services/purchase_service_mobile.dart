import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'store_products.dart';

/// Compras reais via Google Play Billing (Android) / App Store (iOS).
///
/// Os produtos (compra única / "produtos gerenciados") devem ser criados no
/// Play Console com os MESMOS ids de [StoreProducts]. Enquanto não existirem
/// lá, `priceOf` cai no preço de exibição do catálogo.
class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final Map<String, ProductDetails> _products = {};
  bool _available = false;

  void Function(String productId)? _onGrant;
  void Function(String productId)? _onSubGrant;
  void Function(Set<String> activeIds)? _onSubsReconciled;
  final Set<String> _restoredSubs = {};
  bool _reconciling = false;
  bool get isAvailable => _available;

  void onEntitlement(void Function(String productId) cb) => _onGrant = cb;
  void onSubscriptionGranted(void Function(String productId) cb) =>
      _onSubGrant = cb;
  void onSubscriptionsReconciled(void Function(Set<String> activeIds) cb) =>
      _onSubsReconciled = cb;

  Future<void> init() async {
    _available = await _iap.isAvailable();
    if (!_available) return;

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e) => debugPrint('purchaseStream erro: $e'),
      onDone: () => _sub?.cancel(),
    );

    try {
      final resp = await _iap.queryProductDetails(StoreProducts.allIds);
      for (final p in resp.productDetails) {
        _products[p.id] = p;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('queryProductDetails falhou: $e');
    }

    // Recupera compras já feitas e revalida quais assinaturas estão ativas.
    await _reconcile();
  }

  /// Restaura as compras e, após uma janela, consolida o conjunto de
  /// assinaturas que voltaram (ou seja, ainda ativas). Assinatura cancelada
  /// não é restaurada pela Play, então cai fora do conjunto e o premium expira.
  Future<void> _reconcile() async {
    _reconciling = true;
    _restoredSubs.clear();
    await _iap.restorePurchases();
    Future.delayed(const Duration(seconds: 6), () {
      if (!_reconciling) return;
      _reconciling = false;
      _onSubsReconciled?.call(Set<String>.of(_restoredSubs));
    });
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final pd in purchases) {
      if (pd.status == PurchaseStatus.purchased ||
          pd.status == PurchaseStatus.restored) {
        if (StoreProducts.subscriptionIds.contains(pd.productID)) {
          _restoredSubs.add(pd.productID);
          _onSubGrant?.call(pd.productID);
        } else {
          _onGrant?.call(pd.productID);
        }
      }
      if (pd.pendingCompletePurchase) {
        await _iap.completePurchase(pd);
      }
    }
  }

  String priceOf(String productId) =>
      _products[productId]?.price ??
      StoreProducts.byId(productId)?.fallbackPrice ??
      '';

  Future<PurchaseResult> buy(String productId) async {
    if (!_available) return PurchaseResult.unavailable;
    final product = _products[productId];
    if (product == null) return PurchaseResult.unavailable;
    try {
      final param = PurchaseParam(productDetails: product);
      final started = await _iap.buyNonConsumable(purchaseParam: param);
      // O resultado final chega pelo purchaseStream (assíncrono).
      return started ? PurchaseResult.pending : PurchaseResult.error;
    } catch (e) {
      debugPrint('buy falhou: $e');
      return PurchaseResult.error;
    }
  }

  Future<void> restore() async {
    if (_available) await _reconcile();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
