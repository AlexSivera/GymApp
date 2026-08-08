import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/services/ranking_engine/compute_rank.dart';
import 'package:gymapp/services/ranking_engine/rank_tier.dart';

void main() {
  test('lifting exactly the baseline lands in Plata (the calibration point)', () {
    final rank = computeRank(estimated1RM: 40, baseline1RM: 40);
    expect(rank.tier, RankTier.plata);
  });

  test('well below baseline lands in Hierro', () {
    final rank = computeRank(estimated1RM: 10, baseline1RM: 40);
    expect(rank.tier, RankTier.hierro);
  });

  test('rank tier is monotonically non-decreasing as 1RM increases', () {
    const baseline = 40.0;
    var lastScore = 0.0;
    for (var oneRm = 5.0; oneRm <= 400; oneRm += 5) {
      final rank = computeRank(estimated1RM: oneRm, baseline1RM: baseline);
      expect(rank.score, greaterThanOrEqualTo(lastScore));
      lastScore = rank.score;
    }
  });

  test('a huge multiple of the baseline reaches Maestro', () {
    final rank = computeRank(estimated1RM: 200, baseline1RM: 40);
    expect(rank.tier, RankTier.maestro);
  });

  test('zero or negative baseline falls back to Hierro I instead of dividing by zero', () {
    final rank = computeRank(estimated1RM: 50, baseline1RM: 0);
    expect(rank.tier, RankTier.hierro);
    expect(rank.subTier, 1);
  });

  test('nextStepRatio climbing a subtier stays within the same tier', () {
    final ratio = nextStepRatio(const Rank(RankTier.plata, 1))!;
    final next = computeRank(estimated1RM: ratio * 40 * 1.0001, baseline1RM: 40);
    expect(next.tier, RankTier.plata);
    expect(next.subTier, 2);
  });

  test('nextStepRatio at subtier III crosses into the next tier', () {
    final ratio = nextStepRatio(const Rank(RankTier.plata, 3))!;
    final next = computeRank(estimated1RM: ratio * 40 * 1.0001, baseline1RM: 40);
    expect(next.tier, RankTier.oro);
    expect(next.subTier, 1);
  });

  test('nextStepRatio is null once Maestro III is reached — nowhere higher to climb', () {
    expect(nextStepRatio(const Rank(RankTier.maestro, 3)), isNull);
  });
}
