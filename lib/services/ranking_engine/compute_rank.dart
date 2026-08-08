import 'rank_tier.dart';

// Ratio (estimated 1RM ÷ personal baseline) at which each tier begins.
// Plata starts at 0.85 and Oro at 1.15, so the baseline estimate (ratio
// 1.0 — "an untrained ~83kg/27yo could lift this") lands in the middle of
// Plata, matching the reference point used to calibrate strength_standards.dart.
const _tierStart = <RankTier, double>{
  RankTier.hierro: 0,
  RankTier.bronce: 0.62,
  RankTier.plata: 0.85,
  RankTier.oro: 1.15,
  RankTier.platino: 1.5,
  RankTier.esmeralda: 1.9,
  RankTier.diamante: 2.35,
  RankTier.maestro: 2.85,
};

// Maps an estimated 1RM against a personal baseline 1RM onto the rank
// ladder, including progress within the tier (I/II/III).
Rank computeRank({required double estimated1RM, required double baseline1RM}) {
  if (baseline1RM <= 0) return const Rank(RankTier.hierro, 1);
  final ratio = estimated1RM / baseline1RM;

  var tier = RankTier.hierro;
  for (final candidate in RankTier.values) {
    if (ratio >= _tierStart[candidate]!) tier = candidate;
  }

  final start = _tierStart[tier]!;
  final nextIndex = tier.index + 1;
  final end = nextIndex < RankTier.values.length ? _tierStart[RankTier.values[nextIndex]]! : start * 1.4;
  final within = ((ratio - start) / (end - start)).clamp(0.0, 0.999);

  final subTier = (within * 3).floor() + 1;
  return Rank(tier, subTier.clamp(1, 3));
}
