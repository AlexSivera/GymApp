import 'dart:convert';
import 'dart:ui' show Color;

import 'dragon_balls.dart' show weekStartOf;

// Keys of the ZKeyValues table.
class ZKeys {
  ZKeys._();

  static const sound = 'sound_enabled';
  static const over9000Seen = 'over9000_seen';
  static const title = 'title';
  static const aura = 'aura';
  static const wishes = 'wishes';
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

const zUnlockableAuras = [
  ZAura('ultra_instinto', 'Ultra Instinto', Color(0xFFE6ECF7)),
  ZAura('ssj_blue', 'Super Saiyan Blue', Color(0xFF3CC8FF)),
  ZAura('divino', 'Ki divino', Color(0xFFFF4F8B)),
  ZAura('kaioken', 'Kaioken', Color(0xFFFF3D45)),
];

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

  ZAura? get aura => zUnlockableAuras.where((a) => a.id == auraId).firstOrNull;

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
      ];

  List<ZAura> get ownedAuras => [
        for (final wish in wishes)
          if (wish.type == WishType.aura) ...zUnlockableAuras.where((a) => a.id == wish.value),
      ];

  // What each wish would grant right now (null = nothing left to unlock).
  ZAura? get nextAura => zUnlockableAuras.where((a) => !ownedAuras.contains(a)).firstOrNull;
  String? get nextTitle => zUnlockableTitles.where((t) => !ownedTitles.contains(t)).firstOrNull;

  // The week a "semana libre" granted now would protect: this week if it
  // hasn't earned its esfera yet, otherwise next week.
  static DateTime freeWeekFor({required DateTime now, required bool thisWeekMet}) {
    final week = weekStartOf(now);
    return thisWeekMet ? week.add(const Duration(days: 7)) : week;
  }

  static String encodeWishes(List<GrantedWish> wishes) => jsonEncode([for (final w in wishes) w.toJson()]);
}
