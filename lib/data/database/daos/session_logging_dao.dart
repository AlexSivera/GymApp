import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/workout_sessions_table.dart';

part 'session_logging_dao.g.dart';

@DriftAccessor(tables: [SessionExercises, WorkoutSets])
class SessionLoggingDao extends DatabaseAccessor<AppDatabase>
    with _$SessionLoggingDaoMixin {
  SessionLoggingDao(super.db);

  Stream<List<SessionExercise>> watchSessionExercises(int workoutSessionId) {
    return (select(sessionExercises)
          ..where((e) => e.workoutSessionId.equals(workoutSessionId))
          ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
        .watch();
  }

  Future<int> addSessionExercise(SessionExercisesCompanion entry) {
    return into(sessionExercises).insert(entry);
  }

  Future<int> removeSessionExercise(int id) {
    return (delete(sessionExercises)..where((e) => e.id.equals(id))).go();
  }

  Stream<SessionExercise?> watchById(int id) {
    return (select(sessionExercises)..where((e) => e.id.equals(id))).watchSingleOrNull();
  }

  Future<void> updateSessionExerciseStatus(int id, SessionExerciseStatus status) {
    return (update(sessionExercises)..where((e) => e.id.equals(id)))
        .write(SessionExercisesCompanion(status: Value(status)));
  }

  Future<bool> updateSessionExercise(SessionExercise entry) {
    return update(sessionExercises).replace(entry);
  }

  // Persists a new top-to-bottom order after a drag-and-drop reorder.
  Future<void> reorderSessionExercises(List<int> sessionExerciseIdsInOrder) async {
    await batch((b) {
      for (var i = 0; i < sessionExerciseIdsInOrder.length; i++) {
        b.update(
          sessionExercises,
          SessionExercisesCompanion(orderIndex: Value(i)),
          where: (e) => e.id.equals(sessionExerciseIdsInOrder[i]),
        );
      }
    });
  }

  Stream<List<WorkoutSet>> watchSets(int sessionExerciseId) {
    return (select(workoutSets)
          ..where((s) => s.sessionExerciseId.equals(sessionExerciseId))
          ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
        .watch();
  }

  // Every set of a session, across all of its exercises — for session-wide
  // numbers (series progress in Entreno, "N ejercicios" on a finished one).
  Stream<List<WorkoutSet>> watchSetsForSession(int workoutSessionId) {
    final query = select(workoutSets).join([
      innerJoin(sessionExercises, sessionExercises.id.equalsExp(workoutSets.sessionExerciseId)),
    ])
      ..where(sessionExercises.workoutSessionId.equals(workoutSessionId));
    return query.watch().map((rows) => [for (final row in rows) row.readTable(workoutSets)]);
  }

  Future<List<WorkoutSet>> getSets(int sessionExerciseId) {
    return (select(workoutSets)
          ..where((s) => s.sessionExerciseId.equals(sessionExerciseId))
          ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
        .get();
  }

  Future<int> addSet(WorkoutSetsCompanion entry) {
    return into(workoutSets).insert(entry);
  }

  Future<bool> updateSet(WorkoutSet set) {
    return update(workoutSets).replace(set);
  }

  Future<int> deleteSet(int id) {
    return (delete(workoutSets)..where((s) => s.id.equals(id))).go();
  }

  // Opening an exercise mid-workout pre-creates (and pre-fills) all of its
  // planned sets, so a finished session can still hold sets the user never
  // ticked off. Those were never performed and must not count towards
  // volume, PRs, ranks or "Última vez" — every one of those queries only
  // checks weightKg/reps, not isCompleted — so they're dropped once the
  // session is over. Scoped to one session when finishing it; run with no
  // sessionId at startup to clean up sessions finished before this existed.
  Future<int> deleteUncompletedSetsOfFinishedSessions({int? sessionId}) {
    return customUpdate(
      'DELETE FROM workout_sets WHERE is_completed = 0 AND session_exercise_id IN ('
      'SELECT se.id FROM session_exercises se '
      'JOIN workout_sessions ws ON ws.id = se.workout_session_id '
      'WHERE ws.status = ?${sessionId == null ? '' : ' AND ws.id = ?'})',
      variables: [
        Variable.withInt(SessionStatus.completed.index),
        if (sessionId != null) Variable.withInt(sessionId),
      ],
      updates: {workoutSets},
      updateKind: UpdateKind.delete,
    );
  }
}
