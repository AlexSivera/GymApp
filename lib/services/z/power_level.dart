import 'dart:math' as math;

import '../ranking_engine/rank_tier.dart';

// The scouter reading: one number summing up how strong you are, derived
// from the ranks the app already computes. A rank's score runs 1..24
// (tier × 3 + grade); the level grows exponentially with the average so
// each transformation is a visible jump, and it's calibrated so crossing
// 9.000 lands exactly on reaching Super Saiyan (score 4 → 9.113).
const powerLevelBase = 1.57;
const _powerLevelScale = 1500;
const over9000Threshold = 9000;

int powerLevelForScore(double averageRankScore) =>
    (_powerLevelScale * math.pow(powerLevelBase, averageRankScore)).round();

class PowerReading {
  const PowerReading({required this.averageScore, required this.level, required this.rank});

  // Average over muscles of each muscle's average exercise rank score.
  final double averageScore;
  final int level;
  // averageScore rounded to a tier + grade.
  final Rank rank;

  // Grades left until the next transformation (tier, not grade); null at the
  // top of the ladder.
  int? get gradesToNextTier {
    if (rank.tier == RankTier.values.last) return null;
    return 4 - rank.subTier;
  }

  RankTier? get nextTier =>
      rank.tier == RankTier.values.last ? null : RankTier.values[rank.tier.index + 1];
}

// Score a muscle with no ranked exercise yet counts as (Saiyan ★).
const untrainedMuscleScore = 1.0;

// [scoresByMuscle]: every revealed exercise score, grouped by muscle.
// [allMuscles]: the whole body — any of these without a score counts as
// [untrainedMuscleScore], so one strong lift doesn't make you a Super Saiyan
// Blue; you have to be one everywhere.
PowerReading? computePowerReading(Map<String, List<double>> scoresByMuscle, {Iterable<String> allMuscles = const []}) {
  final trained = {
    for (final entry in scoresByMuscle.entries)
      if (entry.value.isNotEmpty) entry.key: entry.value.reduce((a, b) => a + b) / entry.value.length,
  };
  if (trained.isEmpty) return null;
  final muscleAverages = [
    ...trained.values,
    for (final muscle in allMuscles)
      if (!trained.containsKey(muscle)) untrainedMuscleScore,
  ];
  final average = muscleAverages.reduce((a, b) => a + b) / muscleAverages.length;
  return PowerReading(
    averageScore: average,
    level: powerLevelForScore(average),
    rank: rankForScore(average),
  );
}

Rank rankForScore(double score) {
  final tierIndex = ((score - 1) / 3).floor().clamp(0, RankTier.values.length - 1);
  final subTier = (score - tierIndex * 3).round().clamp(1, 3);
  return Rank(RankTier.values[tierIndex], subTier);
}

// "14.286" — Spanish thousands separator, no decimals.
String formatPowerLevel(int level) {
  final digits = level.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
