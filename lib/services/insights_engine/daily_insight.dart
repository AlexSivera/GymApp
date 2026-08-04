import '../../data/database/app_database.dart';
import '../progression_engine/previous_performance.dart';
import '../progression_engine/suggest_next_load.dart';
import 'weekly_summary.dart';

class DailyInsight {
  const DailyInsight(this.message);

  final String message;
}

// Picks exactly one insight to show on the home screen — never a list.
// The candidate list is built from the same signals the Insights screen
// already computes, and the pick is deterministic per calendar day (seeded
// by the date) so it doesn't flicker between opens of the app on the same day.
Future<DailyInsight> computeDailyInsight(AppDatabase db, {DateTime? now}) async {
  final today = now ?? DateTime.now();
  final candidates = <String>[];

  final weekly = await computeWeeklySummary(db, now: today);
  final volumeChange = weekly.volumeChangePercent;
  if (volumeChange != null && volumeChange.abs() >= 3) {
    final sign = volumeChange >= 0 ? 'aumentado' : 'reducido';
    candidates.add('Has $sign un ${volumeChange.abs().toStringAsFixed(0)}% el volumen esta semana.');
  }

  final muscleGap = await _mostNeglectedMuscle(db, today);
  if (muscleGap != null && muscleGap.daysSince >= 6) {
    candidates.add('Hace ${muscleGap.daysSince} días que no entrenas ${muscleGap.muscle}.');
  }

  final loadTip = await _topExerciseLoadTip(db, today);
  if (loadTip != null) candidates.add(loadTip);

  if (candidates.isEmpty) {
    return const DailyInsight('Registra un entrenamiento para empezar a ver tus progresos aquí.');
  }

  final seed = today.year * 10000 + today.month * 100 + today.day;
  final index = seed % candidates.length;
  return DailyInsight(candidates[index]);
}

class _MuscleGap {
  const _MuscleGap({required this.muscle, required this.daysSince});
  final String muscle;
  final int daysSince;
}

Future<_MuscleGap?> _mostNeglectedMuscle(AppDatabase db, DateTime today) async {
  final allExercises = await db.exercisesDao.watchAll().first;
  final exercisesById = {for (final e in allExercises) e.id: e};
  final trainedIds = await db.progressDao.exerciseIdsWithHistory();
  if (trainedIds.isEmpty) return null;

  final lastTrainedByMuscle = <String, DateTime>{};
  for (final id in trainedIds) {
    final exercise = exercisesById[id];
    if (exercise == null) continue;
    final history = await db.progressDao.estimatedOneRepMaxHistory(id);
    if (history.isEmpty) continue;
    final lastDate = history.last.date;
    for (final muscle in exercise.primaryMuscles) {
      final current = lastTrainedByMuscle[muscle];
      if (current == null || lastDate.isAfter(current)) {
        lastTrainedByMuscle[muscle] = lastDate;
      }
    }
  }
  if (lastTrainedByMuscle.isEmpty) return null;

  final today0 = DateTime(today.year, today.month, today.day);
  var worstMuscle = '';
  var worstGap = -1;
  for (final entry in lastTrainedByMuscle.entries) {
    final gap = today0.difference(DateTime(entry.value.year, entry.value.month, entry.value.day)).inDays;
    if (gap > worstGap) {
      worstGap = gap;
      worstMuscle = entry.key;
    }
  }
  if (worstGap < 0) return null;
  return _MuscleGap(muscle: worstMuscle, daysSince: worstGap);
}

Future<String?> _topExerciseLoadTip(AppDatabase db, DateTime today) async {
  final start = today.subtract(const Duration(days: 30));
  final volumeByExercise = await db.progressDao.volumeByExerciseInRange(start, today);
  if (volumeByExercise.isEmpty) return null;

  final topExerciseId =
      volumeByExercise.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  final allExercises = await db.exercisesDao.watchAll().first;
  final exercise = allExercises.where((e) => e.id == topExerciseId).firstOrNull;
  if (exercise == null) return null;

  final previousSets = await getPreviousSetsForExercise(db, exerciseId: topExerciseId, excludeSessionId: -1);
  if (previousSets.isEmpty) return null;

  final validReps = previousSets.where((s) => s.reps != null).map((s) => s.reps!);
  if (validReps.isEmpty) return null;
  final minRepsUsed = validReps.reduce((a, b) => a < b ? a : b);
  final maxRepsUsed = validReps.reduce((a, b) => a > b ? a : b);

  final suggestion = suggestNextLoad(
    previousSets: previousSets,
    targetRepsMin: minRepsUsed,
    targetRepsMax: maxRepsUsed,
  );
  if (suggestion.suggestedWeight == null) return null;
  return 'En ${exercise.name} puedes probar con ${_fmt(suggestion.suggestedWeight!)} kg.';
}

String _fmt(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
