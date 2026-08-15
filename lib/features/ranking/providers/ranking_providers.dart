import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/ranking_engine/compute_rank.dart';
import '../../../services/ranking_engine/rank_tier.dart';
import '../../../services/ranking_engine/strength_standards.dart';
import '../../exercise_library/providers/exercise_library_providers.dart';

final rankingDaoProvider = Provider((ref) => ref.watch(appDatabaseProvider).rankingDao);

final _bodyWeightDaoProvider = Provider((ref) => ref.watch(appDatabaseProvider).bodyWeightDao);
final _progressDaoProvider = Provider((ref) => ref.watch(appDatabaseProvider).progressDao);

final currentBodyweightProvider = StreamProvider<double>((ref) {
  return ref
      .watch(_bodyWeightDaoProvider)
      .watchLatest()
      .map((log) => log?.weightKg ?? referenceBodyweightKg);
});

final bestSetByExerciseProvider = StreamProvider<Map<int, WorkoutSet>>((ref) {
  return ref.watch(_progressDaoProvider).watchBestSetByExercise();
});

final bestDurationSetByExerciseProvider = StreamProvider<Map<int, WorkoutSet>>((ref) {
  return ref.watch(_progressDaoProvider).watchBestDurationSetByExercise();
});

final acknowledgedRanksProvider = StreamProvider<Map<int, Rank>>((ref) {
  return ref.watch(rankingDaoProvider).watchAcknowledged().map((rows) => {
        for (final row in rows) row.exerciseId: Rank(RankTier.values[row.tierIndex], row.subTier),
      });
});

class ExerciseRankInfo {
  const ExerciseRankInfo({required this.exercise, required this.rank, required this.bestSet});

  final Exercise exercise;
  final Rank rank;
  final WorkoutSet bestSet;
}

// Every exercise that CAN be ranked right now (has a strength-standard
// estimate and at least one logged set), with its live rank — regardless
// of whether the user has stepped through the reveal flow for it yet.
final rankableExercisesProvider = Provider<List<ExerciseRankInfo>>((ref) {
  final exercises = ref.watch(allExercisesProvider).valueOrNull ?? const [];
  final bestSets = ref.watch(bestSetByExerciseProvider).valueOrNull ?? const {};
  final bestDurationSets = ref.watch(bestDurationSetByExerciseProvider).valueOrNull ?? const {};
  final bodyweight = ref.watch(currentBodyweightProvider).valueOrNull ?? referenceBodyweightKg;

  final result = <ExerciseRankInfo>[];
  for (final exercise in exercises) {
    final standard = exerciseStandards[exercise.name];
    if (standard == null) continue;

    final WorkoutSet? bestSet;
    final Rank rank;
    if (standard.baselineHoldSeconds != null) {
      bestSet = bestDurationSets[exercise.id];
      if (bestSet == null) continue;
      rank = computeRank(
        estimated1RM: bestSet.durationSeconds!.toDouble(),
        baseline1RM: standard.baselineHoldSeconds!.toDouble(),
      );
    } else if (standard.baselineReps != null) {
      bestSet = bestSets[exercise.id];
      if (bestSet == null) continue;
      rank = computeRank(
        estimated1RM: bestSet.reps!.toDouble(),
        baseline1RM: standard.baselineReps!.toDouble(),
      );
    } else {
      bestSet = bestSets[exercise.id];
      if (bestSet == null) continue;
      final effectiveOneRm = effectiveOneRepMax(standard, bestSet.weightKg!, bestSet.reps!, bodyweight);
      final baseline = standard.ratio * bodyweight;
      rank = computeRank(estimated1RM: effectiveOneRm, baseline1RM: baseline);
    }

    result.add(ExerciseRankInfo(exercise: exercise, rank: rank, bestSet: bestSet));
  }
  return result;
});

// Rankable but not yet stepped through the reveal flow — this is what
// "Clasificar ejercicios · N restantes" counts.
final unclassifiedExercisesProvider = Provider<List<ExerciseRankInfo>>((ref) {
  final rankable = ref.watch(rankableExercisesProvider);
  final acknowledged = ref.watch(acknowledgedRanksProvider).valueOrNull ?? const {};
  return [for (final info in rankable) if (!acknowledged.containsKey(info.exercise.id)) info];
});

// Only the ones already revealed — what actually shows in the muscle list
// and paints the body diagram. An exercise's rank here stays live (keeps
// climbing) once it's been revealed once; it just doesn't appear at all
// beforehand.
final revealedRankedExercisesProvider = Provider<List<ExerciseRankInfo>>((ref) {
  final rankable = ref.watch(rankableExercisesProvider);
  final acknowledged = ref.watch(acknowledgedRanksProvider).valueOrNull ?? const {};
  return [for (final info in rankable) if (acknowledged.containsKey(info.exercise.id)) info];
});

// Per-muscle rank, averaged over that muscle's revealed exercises.
final muscleRanksProvider = Provider<Map<String, Rank>>((ref) {
  final revealed = ref.watch(revealedRankedExercisesProvider);
  final byMuscle = <String, List<Rank>>{};
  for (final info in revealed) {
    for (final muscle in info.exercise.primaryMuscles) {
      byMuscle.putIfAbsent(muscle, () => []).add(info.rank);
    }
  }
  return {for (final entry in byMuscle.entries) entry.key: averageRank(entry.value)};
});

final overallPredictedRankProvider = Provider<Rank?>((ref) {
  final muscleRanks = ref.watch(muscleRanksProvider);
  if (muscleRanks.isEmpty) return null;
  return averageRank(muscleRanks.values.toList());
});

// Exercises for a given muscle, revealed only, for the muscle-detail sheet.
final exercisesForMuscleProvider = Provider.family<List<ExerciseRankInfo>, String>((ref, muscle) {
  final revealed = ref.watch(revealedRankedExercisesProvider);
  return revealed.where((info) => info.exercise.primaryMuscles.contains(muscle)).toList();
});

// Exactly one of weightKg/reps/seconds is set, matching which ExerciseStandard
// mode the exercise uses (weight ratio, repsBased, or durationBased).
typedef NextRankTarget = ({Rank rank, double? weightKg, int? reps, int? seconds});

class ExerciseRankDetail {
  const ExerciseRankDetail({required this.info, required this.next});

  final ExerciseRankInfo info;
  final NextRankTarget? next;
}

// Everything the exercise rank detail screen's "Rango" tab needs: the live
// rank plus, if there's a step above it, the estimated weight (at the same
// reps as the current best set) that would earn it.
final exerciseRankDetailProvider = Provider.family<ExerciseRankDetail?, int>((ref, exerciseId) {
  final rankable = ref.watch(rankableExercisesProvider);
  ExerciseRankInfo? info;
  for (final item in rankable) {
    if (item.exercise.id == exerciseId) {
      info = item;
      break;
    }
  }
  if (info == null) return null;

  final standard = exerciseStandards[info.exercise.name];
  if (standard == null) return ExerciseRankDetail(info: info, next: null);

  final nextRatio = nextStepRatio(info.rank);
  if (nextRatio == null) return ExerciseRankDetail(info: info, next: null);

  if (standard.baselineHoldSeconds != null) {
    final targetSeconds = nextRatio * standard.baselineHoldSeconds!;
    final nextRank = computeRank(
      estimated1RM: targetSeconds * 1.0001,
      baseline1RM: standard.baselineHoldSeconds!.toDouble(),
    );
    return ExerciseRankDetail(
      info: info,
      next: (rank: nextRank, weightKg: null, reps: null, seconds: targetSeconds.ceil()),
    );
  }

  if (standard.baselineReps != null) {
    final targetReps = nextRatio * standard.baselineReps!;
    final nextRank = computeRank(
      estimated1RM: targetReps * 1.0001,
      baseline1RM: standard.baselineReps!.toDouble(),
    );
    return ExerciseRankDetail(
      info: info,
      next: (rank: nextRank, weightKg: null, reps: targetReps.ceil(), seconds: null),
    );
  }

  final bodyweight = ref.watch(currentBodyweightProvider).valueOrNull ?? referenceBodyweightKg;
  final baseline = standard.ratio * bodyweight;
  final targetOneRm = nextRatio * baseline;
  final reps = info.bestSet.reps!;
  // Same Epley-on-total-load model as effectiveOneRepMax: solve for the load
  // first (undoing the rep multiplier), *then* strip bodyweight back out.
  final targetLoad = reps <= 1 ? targetOneRm : targetOneRm / (1 + reps / 30.0);
  final targetWeight = standard.bodyweightBased ? targetLoad - bodyweight : targetLoad;
  final nextRank = computeRank(estimated1RM: targetOneRm * 1.0001, baseline1RM: baseline);

  return ExerciseRankDetail(
    info: info,
    next: (rank: nextRank, weightKg: targetWeight, reps: null, seconds: null),
  );
});

Rank averageRank(List<Rank> ranks) {
  final avgScore = ranks.map((r) => r.score).reduce((a, b) => a + b) / ranks.length;
  final tierIndex = ((avgScore - 1) / 3).floor().clamp(0, RankTier.values.length - 1);
  final subTier = (avgScore - tierIndex * 3).round().clamp(1, 3);
  return Rank(RankTier.values[tierIndex], subTier);
}
