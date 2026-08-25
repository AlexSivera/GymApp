import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/streak.dart';
import '../../../core/utils/weight_unit.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/calories_engine/estimate_calories_burned.dart';
import '../../../services/calories_engine/resolve_session_calories.dart';
import '../../../services/insights_engine/daily_insight.dart';
import '../../../services/insights_engine/weekly_summary.dart';

final _workoutSessionsDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).workoutSessionsDao,
);

final _sessionLoggingDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).sessionLoggingDao,
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

final workoutStreakProvider = StreamProvider<int>((ref) {
  return ref
      .watch(_workoutSessionsDaoProvider)
      .watchRecentCompletedSessions()
      .map((sessions) => calculateWorkoutStreak(sessions.map((s) => s.date).toList()));
});

final userSettingsProvider = StreamProvider<UserSetting?>((ref) {
  return ref.watch(_userSettingsDaoProvider).watchSettings();
});

class WeeklyGoal {
  const WeeklyGoal({required this.completed, required this.target, required this.completedByWeekday});
  final int completed;
  final int target;

  // 7 entries, Monday first — whether a session was completed that day.
  // Powers the day-dot row on WeeklyGoalCard.
  final List<bool> completedByWeekday;
}

// Derived synchronously from the two streams above so the progress bar
// updates the instant a session completes, without its own async plumbing.
final weeklyGoalProvider = Provider<WeeklyGoal>((ref) {
  final sessions = ref.watch(_recentCompletedSessionsProvider).valueOrNull ?? const [];
  final target = ref.watch(userSettingsProvider).valueOrNull?.weeklyTargetSessions ?? 4;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
  final completedThisWeek = sessions.where((s) => !s.date.isBefore(startOfWeek)).toList();
  final completedByWeekday = List<bool>.generate(7, (i) {
    final day = startOfWeek.add(Duration(days: i));
    return completedThisWeek.any((s) {
      final sessionDay = DateTime(s.date.year, s.date.month, s.date.day);
      return sessionDay == day;
    });
  });
  return WeeklyGoal(
    completed: completedThisWeek.length,
    target: target,
    completedByWeekday: completedByWeekday,
  );
});

final _recentCompletedSessionsProvider = StreamProvider<List<WorkoutSession>>((ref) {
  return ref.watch(_workoutSessionsDaoProvider).watchRecentCompletedSessions();
});

final insightOfDayProvider = FutureProvider<DailyInsight>((ref) {
  final unit = weightUnitFromSetting(ref.watch(userSettingsProvider).valueOrNull?.units);
  return computeDailyInsight(ref.watch(appDatabaseProvider), unit: unit);
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
    total += await resolveSessionCalories(db, session: session, profile: profile);
  }
  return total;
});

// Last 3 completed sessions, most recent first — powers the "Actividad
// reciente" feed.
final recentActivityProvider = StreamProvider<List<WorkoutSession>>((ref) {
  return ref.watch(_workoutSessionsDaoProvider).watchRecentCompletedSessions(limit: 3);
});

final sessionExerciseCountProvider = StreamProvider.family<int, int>((ref, sessionId) {
  return ref
      .watch(_sessionLoggingDaoProvider)
      .watchSessionExercises(sessionId)
      .map((exercises) => exercises.length);
});

// Re-derives whenever a session completes, so the weekly volume trend on the
// progress card stays live without its own stream plumbing.
final weeklySummaryProvider = FutureProvider<WeeklySummary>((ref) async {
  ref.watch(_recentCompletedSessionsProvider);
  return computeWeeklySummary(ref.watch(appDatabaseProvider));
});
