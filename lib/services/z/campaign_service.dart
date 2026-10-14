import '../../data/database/app_database.dart';
import 'campaign.dart';
import 'dragon_balls.dart' show weekStartOf;
import 'z_state.dart';

// Database side of the campaign: loading (and creating on first run),
// resolving finished weeks, and the combat when a session completes the week.

Future<int> _weeklyTarget(AppDatabase db) async {
  final settings = await (db.select(db.userSettings)..limit(1)).getSingleOrNull();
  final target = settings?.weeklyTargetSessions ?? 4;
  return target < 1 ? 1 : target;
}

Future<List<DateTime>> _completedDates(AppDatabase db) async {
  final sessions = await db.workoutSessionsDao.watchRecentCompletedSessions(limit: 100000).first;
  return [for (final s in sessions) s.date];
}

Future<void> _save(AppDatabase db, CampaignState state) => db.zStateDao.write(ZKeys.campaign, state.encode());

// Loads the campaign, starting it at Raditz on first run and resolving any
// week that ended since the last open (its result lands in `unseen`).
Future<CampaignState> loadCampaign(AppDatabase db, {DateTime? now}) async {
  final today = now ?? DateTime.now();
  final stored = CampaignState.decode(await db.zStateDao.read(ZKeys.campaign));
  final state = stored ?? CampaignState.start(today);
  final caughtUp = catchUpCampaign(
    state,
    perWeek: sessionsPerWeek(await _completedDates(db)),
    weeklyTarget: await _weeklyTarget(db),
    now: today,
  );
  if (stored == null || caughtUp.encode() != stored.encode()) await _save(db, caughtUp);
  return caughtUp;
}

// Call right after a session is marked completed.
Future<SessionCombat> campaignAfterSession(AppDatabase db, {DateTime? now}) async {
  final today = now ?? DateTime.now();
  final state = await loadCampaign(db, now: today);
  final week = weekStartOf(today);
  final doneThisWeek = (await _completedDates(db)).where((d) => !weekStartOf(d).isBefore(week)).length;
  final result = onSessionCompleted(state, doneThisWeek: doneThisWeek, weeklyTarget: await _weeklyTarget(db), now: today);
  if (result.state.encode() != state.encode()) await _save(db, result.state);
  return result;
}

Future<void> markCampaignEventsSeen(AppDatabase db) async {
  final state = CampaignState.decode(await db.zStateDao.read(ZKeys.campaign));
  if (state == null || state.unseen.isEmpty) return;
  await _save(db, state.copyWith(unseen: const []));
}

Future<void> joinMaster(AppDatabase db, String id, {DateTime? at}) async {
  final current = ZState({ZKeys.masters: ?(await db.zStateDao.read(ZKeys.masters))}).joinedMasters;
  if (current.any((m) => m.id == id)) return;
  await db.zStateDao.write(ZKeys.masters, ZState.encodeMasters([...current, JoinedMaster(id, at ?? DateTime.now())]));
}
