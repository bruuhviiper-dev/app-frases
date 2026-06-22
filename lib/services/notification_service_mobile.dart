import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/phrases.dart';

/// Agenda a notificação diária da "frase do dia" para criar o hábito de abrir
/// o app todo dia (e gerar impressões de anúncio).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _supported => Platform.isAndroid || Platform.isIOS;

  Future<void> init() async {
    if (_initialized || !_supported) return;
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (!_supported) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Agenda a(s) notificação(ões) diária(s) de frase.
  ///
  /// - Frase do dia no horário [hour]:[minute] (padrão 09:00).
  /// - Opcionalmente uma "frase da noite" às [eveningHour] quando [evening] é
  ///   verdadeiro, usando uma frase diferente da manhã.
  Future<void> scheduleDaily({
    int hour = 9,
    int minute = 0,
    bool evening = false,
    int eveningHour = 20,
  }) async {
    if (!_supported) return;
    if (!_initialized) await init();
    await _plugin.cancelAll();

    // Usa só frases GENÉRICAS no lembrete (evita "Bom dia/Boa noite" em
    // horário que não combina — o lembrete pode tocar a qualquer hora).
    bool timed(String t) {
      final l = t.toLowerCase();
      return l.contains('bom dia') ||
          l.contains('boa tarde') ||
          l.contains('boa noite') ||
          l.contains('boa madrugada') ||
          l.contains('bom-dia');
    }

    final all = PhraseData.allPhrases;
    final generic = all.where((p) => !timed(p.text)).toList();
    final pool = generic.isNotEmpty ? generic : all;
    final dayIndex = DateTime.now().difference(DateTime(2020)).inDays;
    final morning = pool[dayIndex % pool.length];

    await _scheduleAt(0, '✨ Frase do dia', morning.text, hour, minute);
    debugPrint('Frase do dia agendada para ${hour}h$minute');

    if (evening) {
      // Frase diferente da manhã (meia volta na lista), também genérica.
      final night = pool[(dayIndex + pool.length ~/ 2) % pool.length];
      await _scheduleAt(1, '🌙 Frase da noite', night.text, eveningHour, 0);
      debugPrint('Frase da noite agendada para ${eveningHour}h');
    }
  }

  Future<void> _scheduleAt(
      int id, String title, String body, int hour, int minute) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'frase_do_dia',
        'Frase do dia',
        channelDescription: 'Notificação diária com a frase do dia',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async {
    if (!_supported) return;
    await _plugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
