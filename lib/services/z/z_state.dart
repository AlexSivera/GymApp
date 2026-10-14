import 'dart:convert';
import 'dart:ui' show Color;

import 'campaign.dart';
import 'dragon_balls.dart' show addWeeks, weekStartOf;
import 'masters.dart';

// Keys of the ZKeyValues table.
class ZKeys {
  ZKeys._();

  static const sound = 'sound_enabled';
  static const over9000Seen = 'over9000_seen';
  static const title = 'title';
  static const aura = 'aura';
  static const wishes = 'wishes';
  static const campaign = 'campaign';
  // [{id, at}] — masters beaten in their training combat ('kaio' = the
  // Genkidama was taught).
  static const masters = 'masters';
  static const mainMaster = 'main_master';
  static const attack = 'attack';
  static const episodes = 'episodes_enabled';
  static const recapWeek = 'recap_week';
  static const peekDay = 'peek_day';
}

class JoinedMaster {
  const JoinedMaster(this.id, this.at);

  final String id;
  final DateTime at;
}

enum WishType { aura, freeWeek, title }

class GrantedWish {
  const GrantedWish({required this.at, required this.type, this.value, this.weekStart});

  final DateTime at;
  final WishType type;
  // The aura id or title granted.
  final String? value;
  // The week a "semana libre" protects.
  final DateTime? weekStart;

  Map<String, Object?> toJson() => {
        'at': at.toIso8601String(),
        'type': type.name,
        if (value != null) 'value': value,
        if (weekStart != null) 'weekStart': weekStart!.toIso8601String(),
      };

  static GrantedWish? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final at = DateTime.tryParse('${raw['at']}');
    final type = WishType.values.where((t) => t.name == raw['type']).firstOrNull;
    if (at == null || type == null) return null;
    final week = raw['weekStart'] == null ? null : DateTime.tryParse('${raw['weekStart']}');
    return GrantedWish(at: at, type: type, value: raw['value'] as String?, weekStart: week);
  }
}

// Cosmetic auras a wish can unlock for the Ficha de guerrero.
class ZAura {
  const ZAura(this.id, this.label, this.color);

  final String id;
  final String label;
  final Color color;
}

// Auras Shenlong can grant.
const zUnlockableAuras = [
  ZAura('ultra_instinto', 'Ultra Instinto', Color(0xFFF4F6FF)),
  ZAura('ssj_blue', 'Super Saiyan Blue', Color(0xFF2EB8FF)),
  ZAura('divino', 'Ki divino', Color(0xFFFF4F8B)),
  ZAura('kaioken', 'Kaioken', Color(0xFFFF3D45)),
];

// Auras won in the campaign.
const zCampaignAuras = [
  ZAura('majin', 'Aura Majin', Color(0xFFFF5FA8)),
  ZAura('dorada', 'Aura dorada', Color(0xFFFFC21F)),
];

const zAllAuras = [...zUnlockableAuras, ...zCampaignAuras];

const zUnlockableTitles = [
  'Guerrero de las 7 esferas',
  'Discípulo de Kaio-sama',
  'Rival de Vegeta',
  'Orgullo Saiyan',
  'Leyenda de la Kame House',
  'Guerrero legendario',
];

class ZState {
  const ZState(this.raw);

  final Map<String, String> raw;

  bool get soundEnabled => raw[ZKeys.sound] != 'false';
  bool get over9000Seen => raw[ZKeys.over9000Seen] == 'true';
  String? get title => raw[ZKeys.title];
  // Chosen cosmetic aura id; null = follow the current transformation.
  String? get auraId => raw[ZKeys.aura];

  ZAura? get aura => zAllAuras.where((a) => a.id == auraId).firstOrNull;

  CampaignState? get campaign => CampaignState.decode(raw[ZKeys.campaign]);

  List<JoinedMaster> get joinedMasters {
    final source = raw[ZKeys.masters];
    if (source == null) return const [];
    try {
      final list = jsonDecode(source);
      if (list is! List) return const [];
      return [
        for (final item in list)
          if (item is Map && item['id'] is String)
            JoinedMaster(item['id'] as String, DateTime.tryParse('${item['at']}') ?? DateTime(2000)),
      ];
    } on FormatException {
      return const [];
    }
  }

  // Masters on your side: Kaio-sama from the start, plus everyone beaten.
  Set<String> get unlockedMasterIds => {'kaio', for (final m in joinedMasters) m.id};

  String get mainMasterId {
    final id = raw[ZKeys.mainMaster];
    return id != null && unlockedMasterIds.contains(id) ? id : 'kaio';
  }

  Set<String> get unlockedAttackIds => {
        defaultAttackId,
        for (final m in joinedMasters) masterById(m.id).attackId,
        for (final fight in campaign?.defeated ?? const <CampaignFight>[])
          if (fight.reward.attackId != null) fight.reward.attackId!,
      };

  String get attackId {
    final id = raw[ZKeys.attack];
    return id != null && unlockedAttackIds.contains(id) ? id : _bestDefaultAttack;
  }

  // Until the user picks one, the most iconic attack they have.
  String get _bestDefaultAttack => unlockedAttackIds.contains('kamehameha') ? 'kamehameha' : defaultAttackId;

  bool get episodesEnabled => raw[ZKeys.episodes] != 'false';

  DateTime? get recapWeek => DateTime.tryParse(raw[ZKeys.recapWeek] ?? '');

  static String encodeMasters(List<JoinedMaster> list) =>
      jsonEncode([for (final m in list) {'id': m.id, 'at': m.at.toIso8601String()}]);

  List<GrantedWish> get wishes {
    final source = raw[ZKeys.wishes];
    if (source == null) return const [];
    try {
      final list = jsonDecode(source);
      if (list is! List) return const [];
      return [for (final item in list) ?GrantedWish.fromJson(item)];
    } on FormatException {
      return const [];
    }
  }

  DateTime? get lastWishAt {
    final all = wishes;
    if (all.isEmpty) return null;
    return all.map((w) => w.at).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  Set<DateTime> get protectedWeeks => {
        for (final wish in wishes)
          if (wish.type == WishType.freeWeek && wish.weekStart != null) wish.weekStart!,
      };

  List<String> get ownedTitles => [
        for (final wish in wishes)
          if (wish.type == WishType.title && wish.value != null) wish.value!,
        for (final fight in campaign?.defeated ?? const <CampaignFight>[])
          if (fight.reward.title != null) fight.reward.title!,
      ];

  List<ZAura> get ownedAuras => [
        for (final wish in wishes)
          if (wish.type == WishType.aura) ...zUnlockableAuras.where((a) => a.id == wish.value),
        for (final fight in campaign?.defeated ?? const <CampaignFight>[])
          if (fight.reward.auraId != null) ...zCampaignAuras.where((a) => a.id == fight.reward.auraId),
      ];

  // What each wish would grant right now (null = nothing left to unlock).
  ZAura? get nextAura => zUnlockableAuras.where((a) => !ownedAuras.contains(a)).firstOrNull;
  String? get nextTitle => zUnlockableTitles.where((t) => !ownedTitles.contains(t)).firstOrNull;

  // The week a "semana libre" granted now would protect: this week if it
  // hasn't earned its esfera yet, otherwise next week.
  static DateTime freeWeekFor({required DateTime now, required bool thisWeekMet}) {
    final week = weekStartOf(now);
    return thisWeekMet ? addWeeks(week, 1) : week;
  }

  static String encodeWishes(List<GrantedWish> wishes) => jsonEncode([for (final w in wishes) w.toJson()]);
}
