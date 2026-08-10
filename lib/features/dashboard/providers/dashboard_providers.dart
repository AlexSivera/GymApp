import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/streak.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/calories_engine/estimate_calories_burned.dart';
import '../../../services/insights_engine/daily_insight.dart';

final _workoutSessionsDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).workoutSessionsDao,
);

final _bodyWeightDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).bodyWeightDao,
);

final _userSettingsDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).userSettingsDao,
);

final todaysSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  return ref.watch(_workoutSessionsDaoProvider).watchSessionForDate(DateTime.now());
});

final lastCompletedSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  return ref.watch(_workoutSessionsDaoProvider).watchLastCompletedSession();
});

final nextPlannedSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  return ref.watch(_workoutSessionsDaoProvider).watchNextPlannedSession();
});

final latestBodyWeightProvider = StreamProvider<BodyWeightLog?>((ref) {
  return ref.watch(_bodyWeightDaoProvider).watchLatest();
});

final workoutStreakProvider = StreamProvider<int>((ref) {
  return ref
      .watch(_workoutSessionsDaoProvider)
      .watchRecentCompletedSessions()
      .map((sessions) => calculateWorkoutStreak(sessions.map((s) => s.date).toList()));
});

final totalWorkoutsCompletedProvider = StreamProvider<int>((ref) {
  return ref
      .watch(_workoutSessionsDaoProvider)
      .watchRecentCompletedSessions(limit: 100000)
      .map((sessions) => sessions.length);
});

final userSettingsProvider = StreamProvider<UserSetting?>((ref) {
  return ref.watch(_userSettingsDaoProvider).watchSettings();
});

class WeeklyGoal {
  const WeeklyGoal({required this.completed, required this.target});
  final int completed;
  final int target;
}

// Derived synchronously from the two streams above so the progress bar
// updates the instant a session completes, without its own async plumbing.
final weeklyGoalProvider = Provider<WeeklyGoal>((ref) {
  final sessions = ref.watch(_recentCompletedSessionsProvider).valueOrNull ?? const [];
  final target = ref.watch(userSettingsProvider).valueOrNull?.weeklyTargetSessions ?? 4;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
  final completedThisWeek = sessions.where((s) => !s.date.isBefore(startOfWeek)).length;
  return WeeklyGoal(completed: completedThisWeek, target: target);
});

final _recentCompletedSessionsProvider = StreamProvider<List<WorkoutSession>>((ref) {
  return ref.watch(_workoutSessionsDaoProvider).watchRecentCompletedSessions();
});

final insightOfDayProvider = FutureProvider<DailyInsight>((ref) {
  return computeDailyInsight(ref.watch(appDatabaseProvider));
});

// Sums the estimated calorie burn of every workout completed today — someone
// who trains twice in one day (e.g. Push in the morning, abs in the
// evening) sees both added together, not just the last one.
final caloriesBurnedTodayProvider = FutureProvider<double>((ref) async {
  final sessions = ref.watch(_recentCompletedSessionsProvider).valueOrNull ?? const [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todaysSessions = sessions.where((s) {
    final date = DateTime(s.date.year, s.date.month, s.date.day);
    return date == today;
  }).toList();
  if (todaysSessions.isEmpty) return 0.0;

  final db = ref.watch(appDatabaseProvider);
  final profile = await loadUserProfile(db);
  var total = 0.0;
  for (final session in todaysSessions) {
    total += await estimateSessionCalories(db, sessionId: session.id, profile: profile);
  }
  return total;
});
