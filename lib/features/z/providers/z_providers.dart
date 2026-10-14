import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/muscle_groups.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/z/campaign.dart';
import '../../../services/z/dragon_balls.dart';
import '../../../services/z/masters.dart';
import '../../../services/z/genkidama.dart';
import '../../../services/z/power_level.dart';
import '../../../services/z/saga.dart';
import '../../../services/z/z_state.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../ranking/providers/ranking_providers.dart';

final zStateProvider = StreamProvider<ZState>((ref) {
  return ref.watch(appDatabaseProvider).zStateDao.watchAll().map(ZState.new);
});

// Synchronous view with an empty default, for widgets that just need a value.
final zStateValueProvider = Provider<ZState>((ref) {
  return ref.watch(zStateProvider).valueOrNull ?? const ZState({});
});

// The scouter reading over the whole body (see computePowerReading) — null
// until at least one exercise has been ranked.
final powerReadingProvider = Provider<PowerReading?>((ref) {
  final revealed = ref.watch(revealedRankedExercisesProvider);
  final byMuscle = <String, List<double>>{};
  for (final info in revealed) {
    for (final muscle in info.exercise.primaryMuscles) {
      byMuscle.putIfAbsent(muscle, () => []).add(info.rank.score);
    }
  }
  return computePowerReading(byMuscle, allMuscles: muscleGroups.values.expand((m) => m));
});

final dragonBallsProvider = Provider<DragonBallProgress>((ref) {
  final sessions = ref.watch(sessionHistoryProvider).valueOrNull ?? const [];
  final target = ref.watch(userSettingsProvider).valueOrNull?.weeklyTargetSessions ?? 4;
  final state = ref.watch(zStateValueProvider);
  return computeDragonBalls(
    completedDates: [for (final s in sessions) s.date],
    weeklyTarget: target,
    countFrom: state.lastWishAt,
    protectedWeeks: state.protectedWeeks,
  );
});

final genkidamaProvider = FutureProvider<Genkidama>((ref) {
  // Recomputed whenever a session completes.
  ref.watch(sessionHistoryProvider);
  return computeGenkidama(ref.watch(appDatabaseProvider));
});

final completedSessionsCountProvider = Provider<int>((ref) {
  return ref.watch(sessionHistoryProvider).valueOrNull?.length ?? 0;
});

// The saga follows the campaign: it changes when its last villain falls.
final sagaProvider = Provider<Saga>((ref) {
  return ref.watch(campaignProvider)?.saga ?? Saga.saiyan;
});

final campaignProvider = Provider<CampaignState?>((ref) {
  return ref.watch(zStateValueProvider).campaign;
});

class WeekProgress {
  const WeekProgress({required this.done, required this.target, required this.resolved});

  final int done;
  final int target;
  // This week's combat already happened (target met).
  final bool resolved;

  int get remaining => (target - done).clamp(0, target);
  double get attack => projectedDamage(done, target);
}

final weekProgressProvider = Provider<WeekProgress>((ref) {
  final sessions = ref.watch(sessionHistoryProvider).valueOrNull ?? const [];
  final target = ref.watch(userSettingsProvider).valueOrNull?.weeklyTargetSessions ?? 4;
  final week = weekStartOf(DateTime.now());
  final done = sessions.where((s) => !weekStartOf(s.date).isBefore(week)).length;
  final campaign = ref.watch(campaignProvider);
  return WeekProgress(
    done: done,
    target: target < 1 ? 1 : target,
    resolved: campaign != null && !campaign.lastResolvedWeek.isBefore(week),
  );
});

final _recordRowsProvider = StreamProvider<List<PersonalRecord>>((ref) {
  return ref.watch(appDatabaseProvider).personalRecordsDao.watchAllRows();
});

// Records beaten (not first-time baselines) since the campaign began, by
// estimated 1RM — what Vegeta's trial counts.
final beatenRecordsProvider = Provider<int>((ref) {
  final rows = ref.watch(_recordRowsProvider).valueOrNull ?? const [];
  final start = ref.watch(campaignProvider)?.startWeek ?? DateTime.now();
  final byExercise = <int, List<PersonalRecord>>{};
  for (final row in rows) {
    if (row.type != PersonalRecordType.estimatedOneRepMax) continue;
    byExercise.putIfAbsent(row.exerciseId, () => []).add(row);
  }
  var count = 0;
  for (final list in byExercise.values) {
    list.sort((a, b) => a.achievedAt.compareTo(b.achievedAt));
    for (final row in list.skip(1)) {
      if (!row.achievedAt.isBefore(start)) count++;
    }
  }
  return count;
});

// Muscle groups counted for Gohan's trial (the neck is left out — almost
// nobody trains it on purpose).
const _trialGroups = ['Brazos', 'Piernas', 'Espalda', 'Pecho', 'Hombros', 'Abdominales'];

final masterStatsProvider = Provider<MasterStats>((ref) {
  final sessions = ref.watch(sessionHistoryProvider).valueOrNull ?? const [];
  final campaign = ref.watch(campaignProvider);
  final start = campaign?.startWeek ?? weekStartOf(DateTime.now());
  final since = [for (final s in sessions) if (!s.date.isBefore(start)) s.date];
  final target = ref.watch(userSettingsProvider).valueOrNull?.weeklyTargetSessions ?? 4;
  final state = ref.watch(zStateValueProvider);
  final muscleRanks = ref.watch(muscleRanksProvider);
  final rankedGroups = _trialGroups.where((g) => (muscleGroups[g] ?? const []).any(muscleRanks.containsKey)).length;
  return MasterStats(
    sessions: since.length,
    bestWeekStreak: bestWeekStreak(
      sessionsPerWeek(since),
      target < 1 ? 1 : target,
      from: start,
      currentWeek: weekStartOf(DateTime.now()),
      protectedWeeks: state.protectedWeeks,
    ),
    rankedGroups: rankedGroups,
    totalGroups: _trialGroups.length,
    beatenRecords: ref.watch(beatenRecordsProvider),
    averageTier: ref.watch(powerReadingProvider)?.rank.tier,
    summonedShenlong: state.wishes.isNotEmpty,
  );
});

final masterTrialsProvider = Provider<Map<String, MasterTrial>>((ref) {
  final stats = ref.watch(masterStatsProvider);
  return {for (final m in masters) m.id: m.trial(stats)};
});

// Masters whose training combat is ready to be shown: trial done but not
// joined yet ('kaio' = the Genkidama, after the first wish).
final pendingMasterUnlocksProvider = Provider<List<Master>>((ref) {
  final state = ref.watch(zStateValueProvider);
  final joined = {for (final m in state.joinedMasters) m.id};
  final trials = ref.watch(masterTrialsProvider);
  return [
    for (final m in masters)
      if (!joined.contains(m.id) && (m.id == 'kaio' ? state.wishes.isNotEmpty : (trials[m.id]?.done ?? false))) m,
  ];
});

final mainMasterProvider = Provider<Master>((ref) => masterById(ref.watch(zStateValueProvider).mainMasterId));

final equippedAttackProvider = Provider<ZAttack>((ref) => attackById(ref.watch(zStateValueProvider).attackId));

// Writes for the GymZ key/value state.
class ZStateActions {
  ZStateActions(this._ref);

  final Ref _ref;

  Future<void> _write(String key, String value) =>
      _ref.read(appDatabaseProvider).zStateDao.write(key, value);

  Future<void> setSoundEnabled(bool value) => _write(ZKeys.sound, '$value');

  Future<void> markOver9000Seen() => _write(ZKeys.over9000Seen, 'true');

  Future<void> setGeneralTierSeen(int tierIndex) => _write(ZKeys.generalTier, '$tierIndex');

  Future<void> setTitle(String title) => _write(ZKeys.title, title);

  Future<void> setMainMaster(String id) => _write(ZKeys.mainMaster, id);

  Future<void> setAttack(String id) => _write(ZKeys.attack, id);

  Future<void> setEpisodesEnabled(bool value) => _write(ZKeys.episodes, '$value');

  Future<void> markRecapShown(DateTime week) => _write(ZKeys.recapWeek, week.toIso8601String());

  Future<void> markPeekShown(DateTime day) => _write(ZKeys.peekDay, '${day.year}-${day.month}-${day.day}');

  // '' = follow the current transformation.
  Future<void> setAura(String auraId) => _write(ZKeys.aura, auraId);

  Future<void> grantWish(GrantedWish wish) async {
    final current = await _ref.read(appDatabaseProvider).zStateDao.read(ZKeys.wishes);
    final wishes = [...ZState({ZKeys.wishes: ?current}).wishes, wish];
    await _write(ZKeys.wishes, ZState.encodeWishes(wishes));
    switch (wish.type) {
      case WishType.aura:
        if (wish.value != null) await setAura(wish.value!);
      case WishType.title:
        if (wish.value != null) await setTitle(wish.value!);
      case WishType.freeWeek:
        break;
    }
  }
}

final zStateActionsProvider = Provider<ZStateActions>(ZStateActions.new);
