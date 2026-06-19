// Notificações reais no mobile; stub no web.
export 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_mobile.dart';
