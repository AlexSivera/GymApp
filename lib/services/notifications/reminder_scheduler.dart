import '../../core/utils/streak.dart';
import '../../data/database/app_database.dart';
import 'notification_service.dart';

const todayReminderNotificationId = 2001;
const streakRiskNotificationId = 2002;

// Re-evaluates whether the "hoy toca entrenar" / "tu racha está en riesgo"
// reminders should fire today, and (re)schedules or cancels them
// accordingly. Always cancels first, so it's safe to call repeatedly —
// on app launch and whenever today's session or the streak change (a
// completed/skipped session should silence "hoy toca entrenar" immediately
// rather than wait for a stale notification to fire anyway).
Future<void> refreshDailyReminders(AppDatabase db) async {
  final settings = await db.userSettingsDao.watchSettings().first;
  if (settings == null || !settings.remindersEnabled) {
    await NotificationService.cancelReminder(todayReminderNotificationId);
    await NotificationService.cancelReminder(streakRiskNotificationId);
    return;
  }

  final now = DateTime.now();
  final reminderTime = DateTime(now.year, now.month, now.day, 18, 0);

  await NotificationService.cancelReminder(todayReminderNotificationId);
  final todaySession = await db.workoutSessionsDao.watchSessionForDate(now).first;
  if (todaySession != null &&
      todaySession.status == SessionStatus.planned &&
      reminderTime.isAfter(now)) {
    await NotificationService.scheduleReminder(
      id: todayReminderNotificationId,
      title: 'Hoy toca entrenar',
      body: 'Tienes un entrenamiento planificado para hoy.',
      fireAt: reminderTime,
    );
  }

  await NotificationService.cancelReminder(streakRiskNotificationId);
  final recent = await db.workoutSessionsDao.watchRecentCompletedSessions().first;
  final streak = calculateWorkoutStreak(recent.map((s) => s.date).toList(), now: now);
  if (streak > 0 && recent.isNotEmpty) {
    final lastDate = recent.first.date;
    final daysSince = DateTime(now.year, now.month, now.day)
        .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
        .inDays;
    // The streak actually breaks once the gap exceeds 7 days (see
    // calculateWorkoutStreak) — warn a couple of days ahead of that so
    // there's still time to act on it.
    if (daysSince >= 6 && reminderTime.isAfter(now)) {
      await NotificationService.scheduleReminder(
        id: streakRiskNotificationId,
        title: 'Tu racha está en riesgo',
        body: 'Llevas $daysSince días sin entrenar — entrena hoy para no perderla.',
        fireAt: reminderTime,
      );
    }
  }
}
