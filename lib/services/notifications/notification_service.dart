import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// Wraps flutter_local_notifications for the one thing this app needs it
// for: alerting the user when their rest timer ends, even if the app is
// backgrounded. Scheduled with `inexactAllowWhileIdle` on purpose — a
// rest-timer alert doesn't need to-the-second precision, and that mode
// avoids requesting Android's SCHEDULE_EXACT_ALARM permission.
class NotificationService {
  NotificationService._();

  static const _restTimerNotificationId = 1001;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    // flutter_local_notifications has no web implementation — every other
    // method in this class already no-ops while _initialized is false, so
    // skipping init() here is enough to make the whole service inert on web.
    if (kIsWeb) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidSettings));

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> scheduleRestTimerFinished(Duration delay) async {
    if (!_initialized) return;
    await _plugin.zonedSchedule(
      _restTimerNotificationId,
      'Descanso terminado',
      'Toca para volver a tu entrenamiento.',
      tz.TZDateTime.now(tz.local).add(delay),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rest_timer',
          'Temporizador de descanso',
          channelDescription: 'Avisa cuando termina el descanso entre series.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelRestTimerNotification() async {
    if (!_initialized) return;
    await _plugin.cancel(_restTimerNotificationId);
  }

  // Generic one-shot reminder, reused for both the "hoy toca entrenar" and
  // "racha en riesgo" proactive nudges — [id] keeps them independently
  // cancelable/reschedulable. Same inexact/idle-tolerant scheduling as the
  // rest timer: a day's-notice reminder doesn't need to-the-second precision.
  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
  }) async {
    if (!_initialized) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(fireAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Recordatorios',
          channelDescription: 'Avisos de entrenamiento planificado y racha en riesgo.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id);
  }
}
