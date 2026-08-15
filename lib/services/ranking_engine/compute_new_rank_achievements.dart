import '../../data/database/app_database.dart';
import 'compute_rank.dart';
import 'rank_tier.dart';
import 'strength_standards.dart';

class RankAchievement {
  const RankAchievement({
    required this.exercise,
    required this.rank,
    required this.bestSet,
    required this.previousRank,
  });

  final Exercise exercise;
  final Rank rank;
  final WorkoutSet bestSet;
  final Rank? previousRank;
}

// Looks at the exercises just logged in [sessionId] and detects any newly
// achieved or improved rank — a first-time classification counts too, since
// that's still worth celebrating right after a workout. Persists each
// detected rank as acknowledged so it won't fire again until it's actually
// beaten. Call this only after the session has been marked completed, since
// the best-set query only looks at completed sessions.
Future<List<RankAchievement>> computeNewRankAchievements(
  AppDatabase db, {
  required int sessionId,
}) async {
  final sessionExercises = await db.sessionLoggingDao.watchSessionExercises(sessionId).first;
  final loggedExerciseIds = <int>{};
  for (final sessionExercise in sessionExercises) {
    final sets = await db.sessionLoggingDao.watchSets(sessionExercise.id).first;
    if (sets.any((s) => (s.weightKg != null && s.reps != null) || s.durationSeconds != null)) {
      loggedExerciseIds.add(sessionExercise.exerciseId);
    }
  }
  if (loggedExerciseIds.isEmpty) return const [];

  final allExercises = await db.exercisesDao.watchAll().first;
  final exercisesById = {for (final e in allExercises) e.id: e};
  final bestSets = await db.progressDao.watchBestSetByExercise().first;
  final bestDurationSets = await db.progressDao.watchBestDurationSetByExercise().first;
  final latestBodyWeight = await db.bodyWeightDao.watchLatest().first;
  final bodyweightKg = latestBodyWeight?.weightKg ?? referenceBodyweightKg;
  final acknowledged = await db.rankingDao.watchAcknowledged().first;
  final acknowledgedByExercise = {
    for (final row in acknowledged) row.exerciseId: Rank(RankTier.values[row.tierIndex], row.subTier),
  };

  final achievements = <RankAchievement>[];
  for (final exerciseId in loggedExerciseIds) {
    final exercise = exercisesById[exerciseId];
    final standard = exerciseStandards[exercise?.name];
    if (exercise == null || standard == null) continue;

    final WorkoutSet? bestSet;
    final Rank rank;
    if (standard.baselineHoldSeconds != null) {
      bestSet = bestDurationSets[exerciseId];
      if (bestSet == null) continue;
      rank = computeRank(
        estimated1RM: bestSet.durationSeconds!.toDouble(),
        baseline1RM: standard.baselineHoldSeconds!.toDouble(),
      );
    } else if (standard.baselineReps != null) {
      bestSet = bestSets[exerciseId];
      if (bestSet == null) continue;
      rank = computeRank(
        estimated1RM: bestSet.reps!.toDouble(),
        baseline1RM: standard.baselineReps!.toDouble(),
      );
    } else {
      bestSet = bestSets[exerciseId];
      if (bestSet == null) continue;
      final effectiveOneRm = effectiveOneRepMax(standard, bestSet.weightKg!, bestSet.reps!, bodyweightKg);
      final baseline = standard.ratio * bodyweightKg;
      rank = computeRank(estimated1RM: effectiveOneRm, baseline1RM: baseline);
    }

    final previousRank = acknowledgedByExercise[exerciseId];
    if (previousRank != null && rank.score <= previousRank.score) continue;

    await db.rankingDao.acknowledge(exerciseId, rank.tier.index, rank.subTier);
    achievements.add(RankAchievement(
      exercise: exercise,
      rank: rank,
      bestSet: bestSet,
      previousRank: previousRank,
    ));
  }
  return achievements;
}
