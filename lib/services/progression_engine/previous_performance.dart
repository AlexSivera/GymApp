import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';

// Sets logged for [exerciseId] in the most recent *other* completed session
// that included it — i.e. "what you did last time" for that exercise.
Future<List<WorkoutSet>> getPreviousSetsForExercise(
  AppDatabase db, {
  required int exerciseId,
  required int excludeSessionId,
}) async {
  final sessionQuery = db.select(db.workoutSessions).join([
    innerJoin(db.sessionExercises,
        db.sessionExercises.workoutSessionId.equalsExp(db.workoutSessions.id)),
  ])
    ..where(db.sessionExercises.exerciseId.equals(exerciseId) &
        db.workoutSessions.id.equals(excludeSessionId).not() &
        db.workoutSessions.status.equalsValue(SessionStatus.completed))
    ..orderBy([OrderingTerm.desc(db.workoutSessions.date)])
    ..limit(1);

  final row = await sessionQuery.getSingleOrNull();
  if (row == null) return [];

  final sessionExercise = row.readTable(db.sessionExercises);

  return (db.select(db.workoutSets)
        ..where((s) => s.sessionExerciseId.equals(sessionExercise.id))
        ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
      .get();
}
