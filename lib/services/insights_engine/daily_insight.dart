import '../../core/utils/weight_unit.dart';
import '../../data/database/app_database.dart';
import '../progression_engine/previous_performance.dart';
import '../progression_engine/suggest_next_load.dart';
import 'weekly_summary.dart';

// What the tip is about. GymZ's masters each phrase it their own way (see
// lib/services/z/mentor_lines.dart); [message] is the neutral wording.
enum InsightKind { zenkai, volumeUp, volumeDown, muscleGap, loadTip, empty }

class DailyInsight {
  const DailyInsight(this.message, {this.kind = InsightKind.empty, this.number, this.subject, this.detail});

  final String message;
  final InsightKind kind;
  // Days off (zenkai), % change (volume), days since (muscle gap).
  final int? number;
  // Muscle (gap) or exercise (load tip).
  final String? subject;
  // Suggested weight, already formatted (load tip).
  final String? detail;
}

// Picks exactly one insight to show on the home screen — never a list.
// The candidate list is built from the same signals the Insights screen
// already computes, and the pick is deterministic per calendar day (seeded
// by the date) so it doesn't flicker between opens of the app on the same day.
Future<DailyInsight> computeDailyInsight(AppDatabase db, {DateTime? now, WeightUnit unit = WeightUnit.kg}) async {
  final today = now ?? DateTime.now();
  final candidates = <DailyInsight>[];

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
        kind: InsightKind.zenkai,
        number: daysOff,
      );
    }
  }

  final weekly = await computeWeeklySummary(db, now: today);
  final volumeChange = weekly.volumeChangePercent;
  if (volumeChange != null && volumeChange.abs() >= 3) {
    final pct = volumeChange.abs().round();
    candidates.add(volumeChange >= 0
        ? DailyInsight('Tu Genkidama es un $pct % más grande que la semana pasada. ¡Sigue reuniendo energía!',
            kind: InsightKind.volumeUp, number: pct)
        : DailyInsight('Tu Genkidama va un $pct % por debajo de la semana pasada. Aún estás a tiempo de cargarla.',
            kind: InsightKind.volumeDown, number: pct));
  }

  final muscleGap = await _mostNeglectedMuscle(db, today);
  if (muscleGap != null && muscleGap.daysSince >= 6) {
    candidates.add(DailyInsight(
      'Hace ${muscleGap.daysSince} días que no entrenas ${muscleGap.muscle.toLowerCase()}. '
      'Un guerrero desequilibrado no aguanta ni un asalto.',
      kind: InsightKind.muscleGap,
      number: muscleGap.daysSince,
      subject: muscleGap.muscle.toLowerCase(),
    ));
  }

  final loadTip = await _topExerciseLoadTip(db, today, unit);
  if (loadTip != null) candidates.add(loadTip);

  if (candidates.isEmpty) {
    return const DailyInsight(
        'Todavía no he sentido tu energía. Entrena una vez y empezaré a leer tu nivel de poder.',
        kind: InsightKind.empty);
  }

  final seed = today.year * 10000 + today.month * 100 + today.day;
  final index = seed % candidates.length;
  return candidates[index];
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

Future<DailyInsight?> _topExerciseLoadTip(AppDatabase db, DateTime today, WeightUnit unit) async {
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
  final weight = formatWeight(suggestion.suggestedWeight!, unit);
  return DailyInsight(
    '${exercise.name}: sube la gravedad a $weight. Tu cuerpo ya está preparado.',
    kind: InsightKind.loadTip,
    subject: exercise.name,
    detail: weight,
  );
}
