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

final sessionExerciseByIdProvider = StreamProvider.family<SessionExercise?, int>((ref, id) {
  return ref.watch(sessionLoggingDaoProvider).watchById(id);
});

final setsForExerciseProvider = StreamProvider.family<List<WorkoutSet>, int>((ref, sessionExerciseId) {
  return ref.watch(sessionLoggingDaoProvider).watchSets(sessionExerciseId);
});

// The single in-progress session, if any. Drives the dynamic "Entreno" tab:
// it only appears in the bottom nav while this has data.
final activeSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  return ref.watch(_workoutSessionsDaoProvider).watchActiveSession();
});
