import 'dart:convert';

import 'dragon_balls.dart' show addWeeks, weekStartOf;
import 'saga.dart';

// La campaña: one weekly combat against the current villain form. The
// combat resolves on the session that completes the weekly target (always a
// K.O., since a full week deals 100 %) or, if the week ends short, on Sunday
// night with whatever was done. Damage is a share of the form's max HP set
// by how much of the week was completed; a form that survives heals its own
// percentage before the next week's combat, so a boss can't be worn down by
// sheer repetition of half-weeks.

class CampaignReward {
  const CampaignReward({this.title, this.auraId, this.attackId});

  final String? title;
  final String? auraId;
  final String? attackId;

  bool get isEmpty => title == null && auraId == null && attackId == null;
}

class CampaignFight {
  const CampaignFight({
    required this.id,
    required this.villainId,
    required this.villain,
    required this.form,
    required this.saga,
    required this.maxHp,
    required this.healPercent,
    this.reward = const CampaignReward(),
  });

  // Also the media pack slot: jefe_<id>.
  final String id;
  final String villainId;
  final String villain;
  // Null for single-form villains.
  final String? form;
  final Saga saga;
  final int maxHp;
  final int healPercent;
  final CampaignReward reward;

  String get displayName => form == null ? villain : '$villain · $form';
}


const campaignFights = <CampaignFight>[
  // Saga Saiyan
  CampaignFight(id: 'raditz', villainId: 'raditz', villain: 'Raditz', form: null, saga: Saga.saiyan, maxHp: 800, healPercent: 15, reward: CampaignReward(attackId: 'double_sunday')),
  CampaignFight(id: 'nappa', villainId: 'nappa', villain: 'Nappa', form: null, saga: Saga.saiyan, maxHp: 1500, healPercent: 20, reward: CampaignReward(attackId: 'bomber_dx')),
  CampaignFight(id: 'vegeta_normal', villainId: 'vegeta', villain: 'Vegeta', form: 'Normal', saga: Saga.saiyan, maxHp: 3000, healPercent: 25),
  CampaignFight(id: 'vegeta_ozaru', villainId: 'vegeta', villain: 'Vegeta', form: 'Ozaru', saga: Saga.saiyan, maxHp: 4000, healPercent: 35, reward: CampaignReward(title: 'Rival del príncipe')),
  // Saga de Namek
  CampaignFight(id: 'dodoria', villainId: 'dodoria', villain: 'Dodoria', form: null, saga: Saga.namek, maxHp: 1500, healPercent: 15, reward: CampaignReward(title: 'Guerrero de Namek')),
  CampaignFight(id: 'zarbon_normal', villainId: 'zarbon', villain: 'Zarbon', form: 'Normal', saga: Saga.namek, maxHp: 2000, healPercent: 20),
  CampaignFight(id: 'zarbon_monstruo', villainId: 'zarbon', villain: 'Zarbon', form: 'Monstruo', saga: Saga.namek, maxHp: 2500, healPercent: 25, reward: CampaignReward(title: 'El más bello del universo')),
  CampaignFight(id: 'ginyu', villainId: 'ginyu', villain: 'Ginyu', form: null, saga: Saga.namek, maxHp: 3500, healPercent: 25, reward: CampaignReward(title: 'Fuerzas Especiales Ginyu')),
  CampaignFight(id: 'freezer_1', villainId: 'freezer', villain: 'Freezer', form: '1.ª forma', saga: Saga.namek, maxHp: 4000, healPercent: 25),
  CampaignFight(id: 'freezer_2', villainId: 'freezer', villain: 'Freezer', form: '2.ª forma', saga: Saga.namek, maxHp: 5000, healPercent: 30),
  CampaignFight(id: 'freezer_3', villainId: 'freezer', villain: 'Freezer', form: '3.ª forma', saga: Saga.namek, maxHp: 6000, healPercent: 35),
  CampaignFight(id: 'freezer_final', villainId: 'freezer', villain: 'Freezer', form: 'Forma final', saga: Saga.namek, maxHp: 7000, healPercent: 40),
  CampaignFight(id: 'freezer_100', villainId: 'freezer', villain: 'Freezer', form: 'Al 100 %', saga: Saga.namek, maxHp: 9000, healPercent: 50, reward: CampaignReward(attackId: 'rayo_mortal', title: 'Superviviente de Namek')),
  // Saga de los Androides
  CampaignFight(id: 'a19', villainId: 'a19', villain: 'Androide 19', form: null, saga: Saga.androides, maxHp: 3000, healPercent: 30, reward: CampaignReward(title: 'Desguazador')),
  CampaignFight(id: 'a18', villainId: 'a18', villain: 'Androide 18', form: null, saga: Saga.androides, maxHp: 4500, healPercent: 30, reward: CampaignReward(title: 'Cazador de androides')),
  CampaignFight(id: 'a17', villainId: 'a17', villain: 'Androide 17', form: null, saga: Saga.androides, maxHp: 5000, healPercent: 35, reward: CampaignReward(attackId: 'barrera_explosiva')),
  CampaignFight(id: 'cell_imperfecto', villainId: 'cell', villain: 'Cell', form: 'Imperfecto', saga: Saga.androides, maxHp: 6000, healPercent: 35),
  CampaignFight(id: 'cell_semiperfecto', villainId: 'cell', villain: 'Cell', form: 'Semiperfecto', saga: Saga.androides, maxHp: 7000, healPercent: 40),
  CampaignFight(id: 'cell_perfecto', villainId: 'cell', villain: 'Cell', form: 'Perfecto', saga: Saga.androides, maxHp: 8000, healPercent: 50, reward: CampaignReward(attackId: 'kamehameha_cell')),
  CampaignFight(id: 'cell_superperfecto', villainId: 'cell', villain: 'Cell', form: 'Superperfecto', saga: Saga.androides, maxHp: 10000, healPercent: 60, reward: CampaignReward(title: 'Campeón de los Juegos de Cell')),
  // Saga de Buu
  CampaignFight(id: 'dabura', villainId: 'dabura', villain: 'Dabura', form: null, saga: Saga.buu, maxHp: 5000, healPercent: 30, reward: CampaignReward(title: 'Vencedor del Reino Demoníaco')),
  CampaignFight(id: 'majin_vegeta', villainId: 'majin_vegeta', villain: 'Majin Vegeta', form: null, saga: Saga.buu, maxHp: 7000, healPercent: 35, reward: CampaignReward(attackId: 'explosion_final')),
  CampaignFight(id: 'buu_gordo', villainId: 'buu', villain: 'Majin Buu', form: 'Gordo', saga: Saga.buu, maxHp: 7000, healPercent: 40),
  CampaignFight(id: 'buu_malo', villainId: 'buu', villain: 'Majin Buu', form: 'Malo', saga: Saga.buu, maxHp: 8000, healPercent: 45),
  CampaignFight(id: 'super_buu', villainId: 'buu', villain: 'Majin Buu', form: 'Super Buu', saga: Saga.buu, maxHp: 9000, healPercent: 50, reward: CampaignReward(attackId: 'rayo_chocolate')),
  CampaignFight(id: 'kid_buu', villainId: 'buu', villain: 'Majin Buu', form: 'Kid Buu', saga: Saga.buu, maxHp: 10000, healPercent: 60, reward: CampaignReward(title: 'Salvador del universo', auraId: 'majin')),
  // Saga Super
  CampaignFight(id: 'freezer_dorado', villainId: 'freezer_dorado', villain: 'Freezer', form: 'Dorado', saga: Saga.superSaga, maxHp: 9000, healPercent: 20, reward: CampaignReward(auraId: 'dorada')),
  CampaignFight(id: 'black_normal', villainId: 'black', villain: 'Goku Black', form: 'Normal', saga: Saga.superSaga, maxHp: 9000, healPercent: 40),
  CampaignFight(id: 'black_rose', villainId: 'black', villain: 'Goku Black', form: 'Rosé', saga: Saga.superSaga, maxHp: 10000, healPercent: 50, reward: CampaignReward(attackId: 'kamehameha_black')),
  CampaignFight(id: 'jiren_normal', villainId: 'jiren', villain: 'Jiren', form: 'Normal', saga: Saga.superSaga, maxHp: 11000, healPercent: 45),
  CampaignFight(id: 'jiren_maximo', villainId: 'jiren', villain: 'Jiren', form: 'Máximo poder', saga: Saga.superSaga, maxHp: 12000, healPercent: 60, reward: CampaignReward(title: 'Campeón del Torneo del Poder')),
];

// Share of the form's max HP a week deals, by fraction of the weekly target
// completed. Agreed curve: 25 % → 15, 50 % → 40, 75 % → 75, 100 % → 100,
// straight lines in between (so any weekly target works).
double weeklyDamage(int done, int target) {
  if (target <= 0 || done <= 0) return 0;
  final r = (done / target).clamp(0.0, 1.0);
  const points = [(0.0, 0.0), (0.25, 0.15), (0.5, 0.40), (0.75, 0.75), (1.0, 1.0)];
  for (var i = 1; i < points.length; i++) {
    final (x1, y1) = points[i];
    if (r <= x1) {
      final (x0, y0) = points[i - 1];
      return y0 + (y1 - y0) * (r - x0) / (x1 - x0);
    }
  }
  return 1;
}

// Every session beyond the weekly target, once the week's combat is won,
// hits the next form in advance — 10 % each, at most 30 %.
const extraHitDamage = 0.10;
const maxExtraHitDamage = 0.30;

const _eps = 1e-9;

// What happened in one weekly combat — shown in the post-workout fight, the
// Monday result and "Anteriormente en GymZ…".
class CampaignEvent {
  const CampaignEvent({
    required this.weekStart,
    required this.fightIndex,
    required this.done,
    required this.target,
    required this.damage,
    required this.hpBefore,
    required this.hpAfter,
    required this.defeated,
    required this.healed,
  });

  final DateTime weekStart;
  final int fightIndex;
  final int done;
  final int target;
  // Fractions of max HP.
  final double damage;
  final double hpBefore;
  final double hpAfter;
  final bool defeated;
  // How much it healed before this combat (0 for a fresh form).
  final double healed;

  CampaignFight get fight => campaignFights[fightIndex];
  CampaignFight? get nextFight => fightIndex + 1 < campaignFights.length ? campaignFights[fightIndex + 1] : null;
  // The same villain changing form (vs. a new villain stepping in).
  bool get transforms => defeated && nextFight != null && nextFight!.villainId == fight.villainId;
  bool get endsSaga => defeated && (nextFight == null || nextFight!.saga != fight.saga);

  Map<String, Object?> toJson() => {
        'w': weekStart.toIso8601String(),
        'i': fightIndex,
        'd': done,
        't': target,
        'dmg': damage,
        'hb': hpBefore,
        'ha': hpAfter,
        'k': defeated,
        'h': healed,
      };

  static CampaignEvent? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final week = DateTime.tryParse('${raw['w']}');
    final index = raw['i'];
    if (week == null || index is! int || index < 0 || index >= campaignFights.length) return null;
    double n(Object? v) => v is num ? v.toDouble() : 0;
    return CampaignEvent(
      weekStart: week,
      fightIndex: index,
      done: raw['d'] is int ? raw['d'] as int : 0,
      target: raw['t'] is int ? raw['t'] as int : 0,
      damage: n(raw['dmg']),
      hpBefore: n(raw['hb']),
      hpAfter: n(raw['ha']),
      defeated: raw['k'] == true,
      healed: n(raw['h']),
    );
  }
}

class CampaignState {
  const CampaignState({
    required this.startWeek,
    required this.lastResolvedWeek,
    required this.fightIndex,
    required this.hp,
    required this.foughtBefore,
    required this.extraHitsThisWeek,
    required this.history,
    required this.unseen,
  });

  // A fresh campaign at Raditz, counting from this week.
  factory CampaignState.start(DateTime now) {
    final week = weekStartOf(now);
    return CampaignState(
      startWeek: week,
      lastResolvedWeek: addWeeks(week, -1),
      fightIndex: 0,
      hp: 1,
      foughtBefore: false,
      extraHitsThisWeek: 0,
      history: const [],
      unseen: const [],
    );
  }

  final DateTime startWeek;
  final DateTime lastResolvedWeek;
  final int fightIndex;
  // Remaining HP of the current form, as a fraction of its max.
  final double hp;
  // The current form already survived a combat (so it heals next week).
  final bool foughtBefore;
  final int extraHitsThisWeek;
  final List<CampaignEvent> history;
  // Combats resolved without the user watching (Sunday night) — shown on
  // the next open.
  final List<CampaignEvent> unseen;

  bool get completed => fightIndex >= campaignFights.length;
  CampaignFight? get current => completed ? null : campaignFights[fightIndex];

  // Fights won so far, oldest first.
  List<CampaignFight> get defeated => campaignFights.take(fightIndex.clamp(0, campaignFights.length)).toList();

  Saga get saga => current?.saga ?? Saga.values.last;

  CampaignState copyWith({
    DateTime? lastResolvedWeek,
    int? fightIndex,
    double? hp,
    bool? foughtBefore,
    int? extraHitsThisWeek,
    List<CampaignEvent>? history,
    List<CampaignEvent>? unseen,
  }) =>
      CampaignState(
        startWeek: startWeek,
        lastResolvedWeek: lastResolvedWeek ?? this.lastResolvedWeek,
        fightIndex: fightIndex ?? this.fightIndex,
        hp: hp ?? this.hp,
        foughtBefore: foughtBefore ?? this.foughtBefore,
        extraHitsThisWeek: extraHitsThisWeek ?? this.extraHitsThisWeek,
        history: history ?? this.history,
        unseen: unseen ?? this.unseen,
      );

  String encode() => jsonEncode({
        'start': startWeek.toIso8601String(),
        'last': lastResolvedWeek.toIso8601String(),
        'i': fightIndex,
        'hp': hp,
        'fought': foughtBefore,
        'extra': extraHitsThisWeek,
        'history': [for (final e in history) e.toJson()],
        'unseen': [for (final e in unseen) e.toJson()],
      });

  static CampaignState? decode(String? source) {
    if (source == null) return null;
    try {
      final raw = jsonDecode(source);
      if (raw is! Map) return null;
      final start = DateTime.tryParse('${raw['start']}');
      final last = DateTime.tryParse('${raw['last']}');
      if (start == null || last == null) return null;
      List<CampaignEvent> events(Object? list) =>
          list is List ? [for (final e in list) ?CampaignEvent.fromJson(e)] : const [];
      return CampaignState(
        startWeek: start,
        lastResolvedWeek: last,
        fightIndex: raw['i'] is int ? raw['i'] as int : 0,
        hp: raw['hp'] is num ? (raw['hp'] as num).toDouble() : 1,
        foughtBefore: raw['fought'] == true,
        extraHitsThisWeek: raw['extra'] is int ? raw['extra'] as int : 0,
        history: events(raw['history']),
        unseen: events(raw['unseen']),
      );
    } on FormatException {
      return null;
    }
  }
}

// Sessions completed per week (keyed by week start).
Map<DateTime, int> sessionsPerWeek(Iterable<DateTime> completedDates) {
  final perWeek = <DateTime, int>{};
  for (final date in completedDates) {
    final week = weekStartOf(date);
    perWeek[week] = (perWeek[week] ?? 0) + 1;
  }
  return perWeek;
}

class _Resolution {
  const _Resolution(this.state, this.event);

  final CampaignState state;
  final CampaignEvent event;
}

_Resolution _resolveWeek(CampaignState state, DateTime week, int done, int target) {
  final fight = state.current!;
  var hp = state.hp;
  var healed = 0.0;
  if (state.foughtBefore && hp < 1) {
    healed = (fight.healPercent / 100).clamp(0.0, 1.0 - hp);
    hp += healed;
  }
  final hpBefore = hp;
  final damage = weeklyDamage(done, target);
  hp = (hp - damage).clamp(0.0, 1.0);
  final defeated = hp <= _eps;
  final event = CampaignEvent(
    weekStart: week,
    fightIndex: state.fightIndex,
    done: done,
    target: target,
    damage: damage,
    hpBefore: hpBefore,
    hpAfter: hp,
    defeated: defeated,
    healed: healed,
  );
  final next = defeated
      ? state.copyWith(fightIndex: state.fightIndex + 1, hp: 1, foughtBefore: false)
      : state.copyWith(hp: hp, foughtBefore: true);
  return _Resolution(
    next.copyWith(lastResolvedWeek: week, extraHitsThisWeek: 0, history: [...state.history, event]),
    event,
  );
}

// Resolves every finished week since the last resolution (Sunday-night
// combats with whatever was done). The current week is left alone — it
// resolves when its target is met. Returned events are also appended to
// `unseen` so the next open can show them.
CampaignState catchUpCampaign(CampaignState state, {required Map<DateTime, int> perWeek, required int weeklyTarget, required DateTime now}) {
  final currentWeek = weekStartOf(now);
  var s = state;
  var week = addWeeks(s.lastResolvedWeek, 1);
  while (week.isBefore(currentWeek) && !s.completed) {
    final resolution = _resolveWeek(s, week, perWeek[week] ?? 0, weeklyTarget);
    s = resolution.state.copyWith(unseen: [...resolution.state.unseen, resolution.event]);
    week = addWeeks(week, 1);
  }
  // Keep lastResolvedWeek moving even once the campaign is over.
  if (s.completed && s.lastResolvedWeek.isBefore(addWeeks(currentWeek, -1))) {
    s = s.copyWith(lastResolvedWeek: addWeeks(currentWeek, -1));
  }
  return s;
}

// What finishing a session did to the campaign.
class SessionCombat {
  const SessionCombat({required this.state, this.event, this.extraHit = 0});

  final CampaignState state;
  // The weekly combat, when this session completed the target.
  final CampaignEvent? event;
  // Advance damage dealt to the next form by a session beyond the target.
  final double extraHit;
}

// Call after a session is marked completed. [doneThisWeek] includes it.
SessionCombat onSessionCompleted(CampaignState state, {required int doneThisWeek, required int weeklyTarget, required DateTime now}) {
  final week = weekStartOf(now);
  if (state.completed) return SessionCombat(state: state);
  final resolvedThisWeek = !state.lastResolvedWeek.isBefore(week);
  if (!resolvedThisWeek) {
    if (doneThisWeek < weeklyTarget) return SessionCombat(state: state);
    final resolution = _resolveWeek(state, week, doneThisWeek, weeklyTarget);
    return SessionCombat(state: resolution.state, event: resolution.event);
  }
  // Already won this week: an extra day softens up the next form.
  if (state.extraHitsThisWeek * extraHitDamage >= maxExtraHitDamage - _eps) return SessionCombat(state: state);
  final hit = extraHitDamage.clamp(0.0, state.hp - 0.01);
  if (hit <= 0) return SessionCombat(state: state);
  return SessionCombat(
    state: state.copyWith(hp: state.hp - hit, extraHitsThisWeek: state.extraHitsThisWeek + 1),
    extraHit: hit,
  );
}

// Damage the current week would deal right now, for the "tu ataque" bar.
double projectedDamage(int doneThisWeek, int weeklyTarget) => weeklyDamage(doneThisWeek, weeklyTarget);
