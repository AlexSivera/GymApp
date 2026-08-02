import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/workout_sessions_table.dart';

part 'workout_sessions_dao.g.dart';

@DriftAccessor(tables: [WorkoutSessions])
class WorkoutSessionsDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutSessionsDaoMixin {
  WorkoutSessionsDao(super.db);

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
}
