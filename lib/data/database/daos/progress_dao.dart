import 'package:drift/drift.dart';

import '../../../services/progression_engine/estimated_one_rep_max.dart';
import '../app_database.dart';
import '../tables/workout_sessions_table.dart';

part 'progress_dao.g.dart';

typedef OneRepMaxPoint = ({DateTime date, double value});

@DriftAccessor(tables: [WorkoutSessions, SessionExercises, WorkoutSets])
class ProgressDao extends DatabaseAccessor<AppDatabase> with _$ProgressDaoMixin {
  ProgressDao(super.db);

  // Best estimated 1RM per calendar day the exercise was trained, oldest first.
  Future<List<OneRepMaxPoint>> estimatedOneRepMaxHistory(int exerciseId) async {
    final query = select(workoutSets).join([
      innerJoin(sessionExercises, sessionExercises.id.equalsExp(workoutSets.sessionExerciseId)),
      innerJoin(workoutSessions, workoutSessions.id.equalsExp(sessionExercises.workoutSessionId)),
    ])
      ..where(sessionExercises.exerciseId.equals(exerciseId) &
          workoutSessions.status.equalsValue(SessionStatus.completed) &
          workoutSets.weightKg.isNotNull() &
          workoutSets.reps.isNotNull())
      ..orderBy([OrderingTerm.asc(workoutSessions.date)]);

    final rows = await query.get();
    final bestPerDay = <DateTime, double>{};
    for (final row in rows) {
      final set = row.readTable(workoutSets);
      final session = row.readTable(workoutSessions);
      final oneRm = estimatedOneRepMax(set.weightKg!, set.reps!);
      final day = DateTime(session.date.year, session.date.month, session.date.day);
      final current = bestPerDay[day];
      if (current == null || oneRm > current) {
        bestPerDay[day] = oneRm;
      }
    }
    final sortedDays = bestPerDay.keys.toList()..sort();
    return [for (final d in sortedDays) (date: d, value: bestPerDay[d]!)];
  }
}
