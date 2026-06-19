// Exporta a implementação real no mobile/desktop (dart:io) e um stub no web.
export 'ads_service_stub.dart'
    if (dart.library.io) 'ads_service_mobile.dart';
