import '../../core/utils/weight_unit.dart';
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
Future<DailyInsight> computeDailyInsight(AppDatabase db, {DateTime? now, WeightUnit unit = WeightUnit.kg}) async {
  final today = now ?? DateTime.now();
  final candidates = <String>[];

  // Zenkai: after a long break, a welcome back instead of a stat — Saiyans
  // come back stronger, but the first day back should be lighter.
  final lastSession = await db.workoutSessionsDao.watchLastCompletedSession().first;
  if (lastSession != null) {
    final daysOff = DateTime(today.year, today.month, today.day)
        .difference(DateTime(lastSession.date.year, lastSession.date.month, lastSession.date.day))
        .inDays;
    if (daysOff >= 10) {
      return DailyInsight(
        '¡Zenkai! Llevas $daysOff días sin entrenar, y los saiyans vuelven más fuertes. '
        'Hoy baja la gravedad un 10 % y deja que el cuerpo despierte.',
      );
    }
  }

  final weekly = await computeWeeklySummary(db, now: today);
  final volumeChange = weekly.volumeChangePercent;
  if (volumeChange != null && volumeChange.abs() >= 3) {
    final pct = volumeChange.abs().toStringAsFixed(0);
    candidates.add(volumeChange >= 0
        ? 'Tu Genkidama es un $pct % más grande que la semana pasada. ¡Sigue reuniendo energía!'
        : 'Tu Genkidama va un $pct % por debajo de la semana pasada. Aún estás a tiempo de cargarla.');
  }

  final muscleGap = await _mostNeglectedMuscle(db, today);
  if (muscleGap != null && muscleGap.daysSince >= 6) {
    candidates.add('Hace ${muscleGap.daysSince} días que no entrenas ${muscleGap.muscle.toLowerCase()}. '
        'Un guerrero desequilibrado no aguanta ni un asalto.');
  }

  final loadTip = await _topExerciseLoadTip(db, today, unit);
  if (loadTip != null) candidates.add(loadTip);

  if (candidates.isEmpty) {
    return const DailyInsight(
        'Todavía no he sentido tu energía. Entrena una vez y empezaré a leer tu nivel de poder.');
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

Future<String?> _topExerciseLoadTip(AppDatabase db, DateTime today, WeightUnit unit) async {
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
  return '${exercise.name}: sube la gravedad a ${formatWeight(suggestion.suggestedWeight!, unit)}. '
      'Tu cuerpo ya está preparado.';
}
