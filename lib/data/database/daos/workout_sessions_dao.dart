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

  // The single in-progress session, if any — drives the dynamic "Entreno" tab.
  Stream<WorkoutSession?> watchActiveSession() {
    return (select(workoutSessions)
          ..where((s) => s.status.equalsValue(SessionStatus.inProgress))
          ..limit(1))
        .watchSingleOrNull();
  }

  // Earliest planned session strictly after today — "próximo entrenamiento".
  Stream<WorkoutSession?> watchNextPlannedSession() {
    final start = DateTime.now();
    final startOfTomorrow = DateTime(start.year, start.month, start.day).add(const Duration(days: 1));
    return (select(workoutSessions)
          ..where((s) =>
              s.status.equalsValue(SessionStatus.planned) &
              s.date.isBiggerOrEqualValue(startOfTomorrow))
          ..orderBy([(s) => OrderingTerm.asc(s.date)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<WorkoutSession?> getSessionForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(workoutSessions)
          ..where((s) =>
              s.date.isBiggerOrEqualValue(start) & s.date.isSmallerThanValue(end))
          ..limit(1))
        .getSingleOrNull();
  }

  // Planned sessions from [date] (inclusive) onward, oldest first — used to
  // find the contiguous chain of upcoming workouts when reorganizing a
  // missed day.
  Future<List<WorkoutSession>> getPlannedSessionsFrom(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    return (select(workoutSessions)
          ..where((s) =>
              s.status.equalsValue(SessionStatus.planned) & s.date.isBiggerOrEqualValue(start))
          ..orderBy([(s) => OrderingTerm.asc(s.date)]))
        .get();
  }

  Future<int> createSession(WorkoutSessionsCompanion entry) {
    return into(workoutSessions).insert(entry);
  }

  Future<void> createSessions(List<WorkoutSessionsCompanion> entries) {
    return batch((b) => b.insertAll(workoutSessions, entries));
  }

  Future<bool> updateSession(WorkoutSession session) {
    return update(workoutSessions).replace(session);
  }

  Future<int> deleteSession(int id) {
    return (delete(workoutSessions)..where((s) => s.id.equals(id))).go();
  }

  Future<void> deleteSessions(List<int> ids) {
    return (delete(workoutSessions)..where((s) => s.id.isIn(ids))).go();
  }
}
