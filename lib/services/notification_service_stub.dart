/// Stub de notificações para web/preview. Mantém a API sem efeitos.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  Future<void> init() async {}
  Future<void> requestPermissions() async {}
  Future<void> scheduleDaily({
    int hour = 9,
    int minute = 0,
    bool evening = false,
    int eveningHour = 20,
  }) async {}
  Future<void> cancelAll() async {}
}
