import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/services/ranking_engine/rank_tier.dart';
import 'package:gymapp/services/z/dragon_balls.dart';
import 'package:gymapp/services/z/power_level.dart';
import 'package:gymapp/services/z/saga.dart';
import 'package:gymapp/services/z/z_state.dart';

void main() {
  group('nivel de poder', () {
    test('crossing 9.000 lands exactly on Super Saiyan (score 10)', () {
      expect(powerLevelForScore(9), lessThan(over9000Threshold));
      expect(powerLevelForScore(10), greaterThan(over9000Threshold));
      expect(rankForScore(10).tier, RankTier.oro);
    });

    test('grows with every grade', () {
      for (var score = 1; score < 24; score++) {
        expect(powerLevelForScore(score + 1.0), greaterThan(powerLevelForScore(score.toDouble())));
      }
    });

    test('averages per muscle first, then across muscles', () {
      final reading = computePowerReading({
        'Pecho': [12, 14], // 13
        'Bíceps': [7], // 7
      })!;
      expect(reading.averageScore, 10);
      expect(reading.rank, const Rank(RankTier.oro, 1));
      expect(reading.gradesToNextTier, 3);
      expect(reading.nextTier, RankTier.platino);
    });

    test('no ranked exercises means no reading', () {
      expect(computePowerReading({}), isNull);
    });

    test('formats with Spanish thousands separators', () {
      expect(formatPowerLevel(14286), '14.286');
      expect(formatPowerLevel(5030274), '5.030.274');
      expect(formatPowerLevel(305), '305');
    });

    test('Kaioken grades read as multipliers', () {
      expect(const Rank(RankTier.plata, 3).label, 'Kaioken ×4');
      expect(const Rank(RankTier.oro, 2).label, 'Super Saiyan II');
    });
  });

  group('esferas del dragón', () {
    // Mondays.
    final w1 = DateTime(2026, 9, 7);
    final w2 = DateTime(2026, 9, 14);
    final w3 = DateTime(2026, 9, 21);
    List<DateTime> sessions(DateTime week, int count) =>
        [for (var i = 0; i < count; i++) week.add(Duration(days: i))];

    test('one esfera per week that met the target', () {
      final progress = computeDragonBalls(
        completedDates: [...sessions(w1, 3), ...sessions(w2, 2), ...sessions(w3, 3)],
        weeklyTarget: 3,
        now: DateTime(2026, 9, 24),
      );
      expect(progress.count, 2);
      expect(progress.thisWeekMet, isTrue);
      expect(progress.thisWeekCompleted, 3);
    });

    test('caps at seven and can summon', () {
      final dates = [
        for (var week = 0; week < 10; week++) ...sessions(w1.add(Duration(days: 7 * week)), 2),
      ];
      final progress = computeDragonBalls(completedDates: dates, weeklyTarget: 2, now: DateTime(2026, 11, 20));
      expect(progress.count, 7);
      expect(progress.canSummon, isTrue);
    });

    test('a wish scatters them: only weeks after the wish week count', () {
      final progress = computeDragonBalls(
        completedDates: [...sessions(w1, 3), ...sessions(w2, 3), ...sessions(w3, 3)],
        weeklyTarget: 3,
        countFrom: DateTime(2026, 9, 16), // during w2
        now: DateTime(2026, 9, 25),
      );
      expect(progress.count, 1); // only w3
    });

    test('a protected week counts even without sessions', () {
      final progress = computeDragonBalls(
        completedDates: sessions(w1, 3),
        weeklyTarget: 3,
        protectedWeeks: {w2},
        now: DateTime(2026, 9, 16),
      );
      expect(progress.count, 2);
      expect(progress.thisWeekMet, isTrue);
    });

    test('remaining this week', () {
      final progress = computeDragonBalls(
        completedDates: sessions(w3, 1),
        weeklyTarget: 4,
        now: DateTime(2026, 9, 23),
      );
      expect(progress.remainingThisWeek, 3);
      expect(progress.count, 0);
    });
  });

  group('sagas', () {
    test('advance with completed sessions', () {
      expect(Saga.forCompletedSessions(0), Saga.saiyan);
      expect(Saga.forCompletedSessions(24), Saga.saiyan);
      expect(Saga.forCompletedSessions(25), Saga.namek);
      expect(Saga.forCompletedSessions(299), Saga.buu);
      expect(Saga.forCompletedSessions(1000), Saga.superSaga);
      expect(Saga.namek.progress(50), 0.5);
    });
  });

  group('deseos', () {
    test('round-trip through JSON and unlock in order', () {
      final wishes = [
        GrantedWish(at: DateTime(2026, 10, 1), type: WishType.title, value: zUnlockableTitles.first),
        GrantedWish(at: DateTime(2026, 11, 20), type: WishType.aura, value: zUnlockableAuras.first.id),
        GrantedWish(at: DateTime(2026, 9, 1), type: WishType.freeWeek, weekStart: DateTime(2026, 9, 7)),
      ];
      final state = ZState({ZKeys.wishes: ZState.encodeWishes(wishes)});
      expect(state.wishes, hasLength(3));
      expect(state.lastWishAt, DateTime(2026, 11, 20));
      expect(state.ownedTitles, [zUnlockableTitles.first]);
      expect(state.nextTitle, zUnlockableTitles[1]);
      expect(state.nextAura, zUnlockableAuras[1]);
      expect(state.protectedWeeks, {DateTime(2026, 9, 7)});
    });

    test('broken stored JSON is ignored, not a crash', () {
      expect(const ZState({ZKeys.wishes: 'nope'}).wishes, isEmpty);
    });

    test('a free week protects this week unless it is already met', () {
      final now = DateTime(2026, 10, 14); // Wednesday
      expect(ZState.freeWeekFor(now: now, thisWeekMet: false), DateTime(2026, 10, 12));
      expect(ZState.freeWeekFor(now: now, thisWeekMet: true), DateTime(2026, 10, 19));
    });

    test('sound is on by default', () {
      expect(const ZState({}).soundEnabled, isTrue);
      expect(const ZState({ZKeys.sound: 'false'}).soundEnabled, isFalse);
    });
  });
}
