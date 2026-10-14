import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/database/database_provider.dart';
import '../../../services/z/campaign.dart';
import '../../../services/z/campaign_service.dart';
import '../../../services/z/dragon_balls.dart';
import '../../../services/z/episodes.dart';
import '../../../services/z/genkidama.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../routines/providers/routines_providers.dart';
import '../providers/z_providers.dart';
import '../screens/boss_fight_screen.dart';
import '../screens/episode_screens.dart';
import '../screens/master_unlock_screen.dart';

// Sits in the Kame House and plays, in order, whatever the user hasn't seen
// yet: the weekly "Anteriormente en GymZ…" (first open of the week), Sunday
// combats resolved while the app was closed, and masters whose trial was
// just passed. Only while the Kame House is the screen on show.
class ZMomentsWatcher extends ConsumerStatefulWidget {
  const ZMomentsWatcher({super.key});

  @override
  ConsumerState<ZMomentsWatcher> createState() => _ZMomentsWatcherState();
}

class _ZMomentsWatcherState extends ConsumerState<ZMomentsWatcher> {
  static bool _running = false;
  bool _caughtUp = false;

  @override
  void initState() {
    super.initState();
    // A week may have ended while the app stayed open in the background.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadCampaign(ref.read(appDatabaseProvider));
      if (mounted) setState(() => _caughtUp = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(zStateProvider).valueOrNull;
    final pendingMasters = ref.watch(pendingMasterUnlocksProvider);
    final visible = TickerMode.valuesOf(context).enabled && (ModalRoute.of(context)?.isCurrent ?? true);
    final campaign = state?.campaign;
    if (!_caughtUp || _running || !visible || state == null || campaign == null) return const SizedBox.shrink();

    final currentWeek = weekStartOf(DateTime.now());
    final needsRecap = state.episodesEnabled &&
        campaign.startWeek.isBefore(currentWeek) &&
        (state.recapWeek == null || state.recapWeek!.isBefore(currentWeek));
    final unseen = campaign.unseen;
    if (!needsRecap && unseen.isEmpty && pendingMasters.isEmpty) return const SizedBox.shrink();

    _running = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _play(needsRecap, unseen, pendingMasters));
    return const SizedBox.shrink();
  }

  Future<void> _play(bool needsRecap, List<CampaignEvent> unseen, List pendingMasters) async {
    final navigator = Navigator.of(context);
    final db = ref.read(appDatabaseProvider);
    final actions = ref.read(zStateActionsProvider);
    try {
      final saga = ref.read(sagaProvider);
      if (needsRecap) {
        final pages = await _buildRecap();
        await navigator.push(RecapScreen.route(pages, saga.mediaSlot));
        await actions.markRecapShown(weekStartOf(DateTime.now()));
        await markCampaignEventsSeen(db);
      } else if (unseen.isNotEmpty) {
        final attack = ref.read(equippedAttackProvider);
        for (final event in unseen) {
          await navigator.push(BossFightScreen.route(event, attack, sundayResult: true));
        }
        await markCampaignEventsSeen(db);
      }
      for (final master in pendingMasters) {
        await joinMaster(db, master.id);
        await navigator.push(MasterUnlockScreen.route(master));
      }
    } finally {
      _running = false;
    }
  }

  Future<List<RecapPage>> _buildRecap() async {
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    final thisWeek = weekStartOf(now);
    final lastWeek = addWeeks(thisWeek, -1);
    final state = ref.read(zStateValueProvider);
    final sessions = ref.read(sessionHistoryProvider).valueOrNull ?? const [];
    final target = ref.read(weekProgressProvider).target;
    final done = sessions.where((s) => weekStartOf(s.date) == lastWeek).length;
    final genkidama = await computeGenkidama(db, now: lastWeek.add(const Duration(days: 3)));
    final records = await db.personalRecordsDao.countAchievedInRange(lastWeek, thisWeek);
    final campaign = state.campaign!;
    return recapPages(RecapInput(
      name: _name(),
      weekStart: lastWeek,
      done: done,
      target: target,
      ballEarned: done >= target || state.protectedWeeks.contains(lastWeek),
      genkidamaPercent: genkidama.percent,
      records: records,
      combats: [for (final e in campaign.history) if (e.weekStart == lastWeek) e],
      mastersJoined: [
        for (final m in state.joinedMasters)
          if (!m.at.isBefore(lastWeek) && m.at.isBefore(thisWeek) && m.id != 'kaio') masterName(m.id),
      ],
      campaign: campaign,
      dragonBalls: ref.read(dragonBallsProvider).count,
    ));
  }

  String _name() {
    final name = ref.read(userSettingsProvider).valueOrNull?.name?.trim();
    return name == null || name.isEmpty ? 'nuestro guerrero' : name;
  }
}

String masterName(String id) => const {
      'kaio': 'Kaio-sama',
      'roshi': 'Roshi',
      'krilin': 'Krilin',
      'piccolo': 'Piccolo',
      'gohan': 'Gohan',
      'trunks': 'Trunks',
      'vegeta': 'Vegeta',
      'goku': 'Goku',
    }[id] ??
    id;

// Everything "¡En el próximo episodio!" needs, after a session.
NextEpisodeInput buildNextEpisodeInput(WidgetRef ref, {CampaignEvent? combat, double extraHit = 0}) {
  final name = ref.read(userSettingsProvider).valueOrNull?.name?.trim();
  final week = ref.read(weekProgressProvider);
  final balls = ref.read(dragonBallsProvider);
  final state = ref.read(zStateValueProvider);
  final trials = ref.read(masterTrialsProvider);
  final joined = state.unlockedMasterIds;

  (String, String)? near;
  var best = 0.6;
  for (final entry in trials.entries) {
    if (joined.contains(entry.key) || entry.value.done || entry.key == 'kaio') continue;
    if (entry.value.progress >= best) {
      best = entry.value.progress;
      near = (masterName(entry.key), entry.value.label);
    }
  }

  String? nextLabel;
  final next = ref.read(nextPlannedSessionProvider).valueOrNull;
  if (next != null) {
    final title = ref.read(routineDaySessionTitleProvider(next.routineDayId));
    nextLabel = '${DateFormat('EEEE d', 'es').format(next.date)}${title == null ? '' : ' · $title'}';
  }

  return NextEpisodeInput(
    name: name == null || name.isEmpty ? 'nuestro guerrero' : name,
    campaign: state.campaign ?? CampaignState.start(DateTime.now()),
    doneThisWeek: week.done,
    weeklyTarget: week.target,
    todaysCombat: combat,
    extraHit: extraHit,
    nextSessionLabel: nextLabel,
    dragonBalls: balls.count,
    thisWeekBallMet: balls.thisWeekMet,
    nearMaster: near,
  );
}
