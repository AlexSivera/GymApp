import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/streak.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';

final _workoutSessionsDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).workoutSessionsDao,
);

final _bodyWeightDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).bodyWeightDao,
);

final todaysSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  return ref.watch(_workoutSessionsDaoProvider).watchSessionForDate(DateTime.now());
});

final lastCompletedSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  return ref.watch(_workoutSessionsDaoProvider).watchLastCompletedSession();
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
