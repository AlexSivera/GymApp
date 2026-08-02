import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';

final sessionLoggingDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).sessionLoggingDao,
);

final _workoutSessionsDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).workoutSessionsDao,
);

final sessionByIdProvider = StreamProvider.family<WorkoutSession?, int>((ref, sessionId) {
  return ref.watch(_workoutSessionsDaoProvider).watchById(sessionId);
});

final sessionExercisesProvider = StreamProvider.family<List<SessionExercise>, int>((ref, sessionId) {
  return ref.watch(sessionLoggingDaoProvider).watchSessionExercises(sessionId);
});

final setsForExerciseProvider = StreamProvider.family<List<WorkoutSet>, int>((ref, sessionExerciseId) {
  return ref.watch(sessionLoggingDaoProvider).watchSets(sessionExerciseId);
});
