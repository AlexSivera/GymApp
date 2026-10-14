import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database_provider.dart';
import '../../../services/z/dragon_balls.dart';
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

// The scouter reading — null until at least one exercise has been ranked.
final powerReadingProvider = Provider<PowerReading?>((ref) {
  final revealed = ref.watch(revealedRankedExercisesProvider);
  final byMuscle = <String, List<double>>{};
  for (final info in revealed) {
    for (final muscle in info.exercise.primaryMuscles) {
      byMuscle.putIfAbsent(muscle, () => []).add(info.rank.score);
    }
  }
  return computePowerReading(byMuscle);
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

final sagaProvider = Provider<Saga>((ref) {
  return Saga.forCompletedSessions(ref.watch(completedSessionsCountProvider));
});

// Writes for the GymZ key/value state.
class ZStateActions {
  ZStateActions(this._ref);

  final Ref _ref;

  Future<void> _write(String key, String value) =>
      _ref.read(appDatabaseProvider).zStateDao.write(key, value);

  Future<void> setSoundEnabled(bool value) => _write(ZKeys.sound, '$value');

  Future<void> markOver9000Seen() => _write(ZKeys.over9000Seen, 'true');

  Future<void> setTitle(String title) => _write(ZKeys.title, title);

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
