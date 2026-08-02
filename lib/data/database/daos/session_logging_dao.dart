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

  Stream<List<WorkoutSet>> watchSets(int sessionExerciseId) {
    return (select(workoutSets)
          ..where((s) => s.sessionExerciseId.equals(sessionExerciseId))
          ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
        .watch();
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
}
