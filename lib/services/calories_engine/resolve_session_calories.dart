import '../../data/database/app_database.dart';
import '../health_connect/health_connect_service.dart';
import 'estimate_calories_burned.dart';

const HealthConnectService _healthConnect = HealthConnectService();

// Prefers the calories a linked wearable (Mi Fitness, etc.) actually
// recorded during the session's own time window — heart-rate-based, so more
// accurate than the MET estimate — and only falls back to the MET-based
// estimateSessionCalories when Health Connect isn't linked or has no data
// for that window (band not worn, not synced yet).
Future<double> resolveSessionCalories(
  AppDatabase db, {
  required WorkoutSession session,
  required UserProfile profile,
}) async {
  final start = session.startedAt;
  final end = session.completedAt;
  if (start != null && end != null) {
    final settings = await db.userSettingsDao.watchSettings().first;
    if (settings?.healthConnectEnabled ?? false) {
      final fromWearable = await _healthConnect.caloriesBurnedInRange(start, end);
      if (fromWearable != null) return fromWearable;
    }
  }
  return estimateSessionCalories(db, sessionId: session.id, profile: profile);
}

// Calories burned across a whole day — used for the Home dashboard's daily
// total, which is meant to reflect the day's overall activity (a wearable's
// all-day burn) rather than only workouts logged inside the app. When Health
// Connect is linked this reads straight from it for [dayStart, now), so it
// has a value even on days with no session at all; only falls back to
// summing today's completed sessions' MET estimates when Health Connect
// isn't linked or has no data yet for the day.
Future<double> resolveDailyCalories(
  AppDatabase db, {
  required DateTime dayStart,
  required List<WorkoutSession> todaysSessions,
  required UserProfile profile,
}) async {
  final settings = await db.userSettingsDao.watchSettings().first;
  if (settings?.healthConnectEnabled ?? false) {
    final fromWearable = await _healthConnect.caloriesBurnedInRange(dayStart, DateTime.now());
    if (fromWearable != null) return fromWearable;
  }

  var total = 0.0;
  for (final session in todaysSessions) {
    total += await estimateSessionCalories(db, sessionId: session.id, profile: profile);
  }
  return total;
}
