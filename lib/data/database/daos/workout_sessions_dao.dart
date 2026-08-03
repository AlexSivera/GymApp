import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/workout_sessions_table.dart';

part 'workout_sessions_dao.g.dart';

@DriftAccessor(tables: [WorkoutSessions])
class WorkoutSessionsDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutSessionsDaoMixin {
  WorkoutSessionsDao(super.db);

  Stream<WorkoutSession?> watchById(int id) {
    return (select(workoutSessions)..where((s) => s.id.equals(id))).watchSingleOrNull();
  }

  Stream<WorkoutSession?> watchSessionForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(workoutSessions)
          ..where((s) =>
              s.date.isBiggerOrEqualValue(start) &
              s.date.isSmallerThanValue(end))
          ..orderBy([(s) => OrderingTerm.desc(s.date)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Stream<WorkoutSession?> watchLastCompletedSession() {
    return (select(workoutSessions)
          ..where((s) => s.status.equalsValue(SessionStatus.completed))
          ..orderBy([(s) => OrderingTerm.desc(s.date)])
          ..limit(1))
        .watchSingleOrNull();
  }

  // Recent completed sessions, most recent first — used to derive the streak.
  Stream<List<WorkoutSession>> watchRecentCompletedSessions({int limit = 90}) {
    return (select(workoutSessions)
          ..where((s) => s.status.equalsValue(SessionStatus.completed))
          ..orderBy([(s) => OrderingTerm.desc(s.date)])
          ..limit(limit))
        .watch();
  }

  // Inclusive of [start], exclusive of [end] — used to draw month markers.
  Stream<List<WorkoutSession>> watchSessionsInRange(DateTime start, DateTime end) {
    return (select(workoutSessions)
          ..where((s) =>
              s.date.isBiggerOrEqualValue(start) & s.date.isSmallerThanValue(end)))
        .watch();
  }

  Future<List<WorkoutSession>> getCompletedSessionsInRange(DateTime start, DateTime end) {
    return (select(workoutSessions)
          ..where((s) =>
              s.status.equalsValue(SessionStatus.completed) &
              s.date.isBiggerOrEqualValue(start) &
              s.date.isSmallerThanValue(end)))
        .get();
  }

  Future<List<WorkoutSession>> getLastCompletedSessionForRoutineDay(
    int routineDayId, {
    required int excludeSessionId,
  }) {
    return (select(workoutSessions)
          ..where((s) =>
              s.routineDayId.equals(routineDayId) &
              s.id.equals(excludeSessionId).not() &
              s.status.equalsValue(SessionStatus.completed))
          ..orderBy([(s) => OrderingTerm.desc(s.date)])
          ..limit(1))
        .get();
  }

  Future<int> createSession(WorkoutSessionsCompanion entry) {
    return into(workoutSessions).insert(entry);
  }

  Future<bool> updateSession(WorkoutSession session) {
    return update(workoutSessions).replace(session);
  }

  Future<int> deleteSession(int id) {
    return (delete(workoutSessions)..where((s) => s.id.equals(id))).go();
  }
}
