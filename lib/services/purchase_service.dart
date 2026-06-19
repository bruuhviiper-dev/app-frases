// Compras reais no mobile (Google Play Billing); simulação no web/preview.
export 'purchase_service_stub.dart'
    if (dart.library.io) 'purchase_service_mobile.dart';
