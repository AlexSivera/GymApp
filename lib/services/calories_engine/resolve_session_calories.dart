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
