import '../../core/utils/streak.dart';
import '../../data/database/app_database.dart';
import '../z/masters.dart';
import '../z/mentor_lines.dart';
import '../z/z_state.dart';
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
  // Reminders come from the user's main master, in their voice.
  final zState = ZState(await db.zStateDao.watchAll().first);
  final master = masterById(zState.mainMasterId);

  await NotificationService.cancelReminder(todayReminderNotificationId);
  final todaySession = await db.workoutSessionsDao.watchSessionForDate(now).first;
  if (todaySession != null &&
      todaySession.status == SessionStatus.planned &&
      reminderTime.isAfter(now)) {
    await NotificationService.scheduleReminder(
      id: todayReminderNotificationId,
      title: master.name,
      body: plannedTodayReminder(master.id),
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
        title: '${master.name}: tu racha está en peligro',
        body: streakRiskReminder(master.id, daysSince),
        fireAt: reminderTime,
      );
    }
  }
}
