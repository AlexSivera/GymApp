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

  // Total volume (Σ weight × reps) across all exercises, [start] inclusive, [end] exclusive.
  Future<double> totalVolumeInRange(DateTime start, DateTime end) async {
    final byExercise = await volumeByExerciseInRange(start, end);
    return byExercise.values.fold<double>(0.0, (sum, v) => sum + v);
  }

  // Volume per exercise in the range — used to roll up into muscle-group totals.
  Future<Map<int, double>> volumeByExerciseInRange(DateTime start, DateTime end) async {
    final query = select(workoutSets).join([
      innerJoin(sessionExercises, sessionExercises.id.equalsExp(workoutSets.sessionExerciseId)),
      innerJoin(workoutSessions, workoutSessions.id.equalsExp(sessionExercises.workoutSessionId)),
    ])
      ..where(workoutSessions.status.equalsValue(SessionStatus.completed) &
          workoutSessions.date.isBiggerOrEqualValue(start) &
          workoutSessions.date.isSmallerThanValue(end) &
          workoutSets.weightKg.isNotNull() &
          workoutSets.reps.isNotNull());

    final rows = await query.get();
    final result = <int, double>{};
    for (final row in rows) {
      final set = row.readTable(workoutSets);
      final sessionExercise = row.readTable(sessionExercises);
      final volume = set.weightKg! * set.reps!;
      result[sessionExercise.exerciseId] = (result[sessionExercise.exerciseId] ?? 0) + volume;
    }
    return result;
  }

  // Exercise ids ordered by most-recently-logged set — powers the exercise
  // picker's "Recientes" tab.
  Future<List<int>> recentlyUsedExerciseIds({int limit = 20}) async {
    final query = select(workoutSets).join([
      innerJoin(sessionExercises, sessionExercises.id.equalsExp(workoutSets.sessionExerciseId)),
    ])
      ..where(workoutSets.completedAt.isNotNull())
      ..orderBy([OrderingTerm.desc(workoutSets.completedAt)]);

    final rows = await query.get();
    final seen = <int>[];
    for (final row in rows) {
      final exerciseId = row.readTable(sessionExercises).exerciseId;
      if (!seen.contains(exerciseId)) seen.add(exerciseId);
      if (seen.length >= limit) break;
    }
    return seen;
  }

  // Distinct exercise ids that have at least one logged set in a completed session.
  Future<List<int>> exerciseIdsWithHistory() async {
    final query = selectOnly(sessionExercises, distinct: true)
      ..addColumns([sessionExercises.exerciseId])
      ..join([
        innerJoin(workoutSessions, workoutSessions.id.equalsExp(sessionExercises.workoutSessionId)),
        innerJoin(workoutSets, workoutSets.sessionExerciseId.equalsExp(sessionExercises.id)),
      ])
      ..where(workoutSessions.status.equalsValue(SessionStatus.completed));

    final rows = await query.get();
    return rows.map((row) => row.read(sessionExercises.exerciseId)!).toList();
  }
}
