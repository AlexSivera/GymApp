import 'dart:ui' show Color;

import '../ranking_engine/rank_tier.dart';
import 'dragon_balls.dart' show addWeeks;

// Los maestros, Xenoverse style: each one is beaten in a "combate de
// entrenamiento" by passing a trial that fits their personality, then joins
// and teaches their attack. One of them (chosen in the Ficha) gives the daily
// tips and reminders; the others cameo in big moments.

// What the trials are measured against — activity since the campaign
// started, plus the user's current strength.
class MasterStats {
  const MasterStats({
    required this.sessions,
    required this.bestWeekStreak,
    required this.rankedGroups,
    required this.totalGroups,
    required this.beatenRecords,
    required this.averageTier,
    required this.summonedShenlong,
  });

  final int sessions;
  final int bestWeekStreak;
  final int rankedGroups;
  final int totalGroups;
  final int beatenRecords;
  final RankTier? averageTier;
  final bool summonedShenlong;
}

class MasterTrial {
  const MasterTrial(this.current, this.goal, this.label);

  final int current;
  final int goal;
  // "6/10 límites superados".
  final String label;

  bool get done => current >= goal;
  double get progress => goal <= 0 ? 1 : (current / goal).clamp(0.0, 1.0);
}

class Master {
  const Master({
    required this.id,
    required this.name,
    required this.kanji,
    required this.color,
    required this.attackId,
    required this.personality,
    required this.trialText,
    required this.trial,
  });

  // Media slots: maestro_<id>_<mood>.
  final String id;
  final String name;
  // Shown in the stand-in orb when the pack has no portrait.
  final String kanji;
  final Color color;
  final String attackId;
  final String personality;
  final String trialText;
  final MasterTrial Function(MasterStats stats) trial;
}

final masters = <Master>[
  Master(
    id: 'kaio',
    name: 'Kaio-sama',
    kanji: '界',
    color: const Color(0xFF3C8CFF),
    attackId: 'genkidama',
    personality: 'Chistes malos y telepatía',
    trialText: 'Desde el principio',
    trial: (s) => const MasterTrial(1, 1, 'Tu primer maestro'),
  ),
  Master(
    id: 'roshi',
    name: 'Roshi',
    kanji: '亀',
    color: const Color(0xFFFF8A3D),
    attackId: 'kamehameha',
    personality: 'Viejo sabio con guasa',
    trialText: 'Tus primeros 5 combates',
    trial: (s) => MasterTrial(s.sessions, 5, '${s.sessions.clamp(0, 5)}/5 combates'),
  ),
  Master(
    id: 'krilin',
    name: 'Krilin',
    kanji: '円',
    color: const Color(0xFFFFB347),
    attackId: 'kienzan',
    personality: 'Inseguro pero animoso',
    trialText: '2 semanas seguidas cumplidas',
    trial: (s) => MasterTrial(s.bestWeekStreak, 2, '${s.bestWeekStreak.clamp(0, 2)}/2 semanas seguidas'),
  ),
  Master(
    id: 'piccolo',
    name: 'Piccolo',
    kanji: '魔',
    color: const Color(0xFF7BE3A8),
    attackId: 'makankosappo',
    personality: 'Seco y exigente',
    trialText: '4 semanas seguidas cumplidas',
    trial: (s) => MasterTrial(s.bestWeekStreak, 4, '${s.bestWeekStreak.clamp(0, 4)}/4 semanas seguidas'),
  ),
  Master(
    id: 'gohan',
    name: 'Gohan',
    kanji: '飯',
    color: const Color(0xFFFFD23F),
    attackId: 'masenko',
    personality: 'Estudioso, te habla del equilibrio',
    trialText: 'Lectura en todos los grupos musculares',
    trial: (s) => MasterTrial(s.rankedGroups, s.totalGroups, '${s.rankedGroups}/${s.totalGroups} grupos con lectura'),
  ),
  Master(
    id: 'trunks',
    name: 'Trunks',
    kanji: '未',
    color: const Color(0xFFB69CFF),
    attackId: 'burning_attack',
    personality: 'Serio, viene del futuro',
    trialText: '25 combates',
    trial: (s) => MasterTrial(s.sessions, 25, '${s.sessions.clamp(0, 25)}/25 combates'),
  ),
  Master(
    id: 'vegeta',
    name: 'Vegeta',
    kanji: '王',
    color: const Color(0xFF5A7BFF),
    attackId: 'galick_gun',
    personality: '"Insecto", orgullo y rivalidad',
    trialText: '10 límites superados (récords)',
    trial: (s) => MasterTrial(s.beatenRecords, 10, '${s.beatenRecords.clamp(0, 10)}/10 límites superados'),
  ),
  Master(
    id: 'goku',
    name: 'Goku',
    kanji: '悟',
    color: const Color(0xFFFF6A13),
    attackId: 'kamehameha_instantaneo',
    personality: 'Alegre, siempre con hambre',
    trialText: 'Tu media llega a Super Saiyan',
    trial: (s) {
      final reached = s.averageTier != null && s.averageTier!.index >= RankTier.oro.index;
      return MasterTrial(reached ? 1 : 0, 1, reached ? 'Super Saiyan alcanzado' : 'Llega a Super Saiyan');
    },
  ),
];

Master masterById(String? id) => masters.firstWhere((m) => m.id == id, orElse: () => masters.first);

// Longest run of consecutive weeks that met the target (protected weeks
// count), among weeks strictly before the current one plus the current one
// if it's already met.
int bestWeekStreak(Map<DateTime, int> perWeek, int target, {required DateTime from, required DateTime currentWeek, Set<DateTime> protectedWeeks = const {}}) {
  var best = 0;
  var run = 0;
  for (var week = from; !week.isAfter(currentWeek); week = addWeeks(week, 1)) {
    final met = (perWeek[week] ?? 0) >= target || protectedWeeks.contains(week);
    if (met) {
      run++;
      if (run > best) best = run;
    } else if (week != currentWeek) {
      run = 0;
    }
  }
  return best;
}

// ---------------------------------------------------------------- Ataques

class ZAttack {
  const ZAttack(this.id, this.name, this.colors, this.source);

  // Media slots: ataque_<id> (video + sound).
  final String id;
  final String name;
  // Beam gradient, outer → core.
  final List<Color> colors;
  // Who teaches it ("Roshi", "Freezer"…), shown in the collection.
  final String source;
}

const defaultAttackId = 'rafaga';

const zAttacks = <ZAttack>[
  ZAttack('rafaga', 'Ráfaga de ki', [Color(0xFF9FB6FF), Color(0xFFE6ECF7)], 'Tu primer ataque'),
  ZAttack('kamehameha', 'Kamehameha', [Color(0xFF3CC8FF), Color(0xFFE6FAFF)], 'Roshi'),
  ZAttack('kienzan', 'Kienzan', [Color(0xFFFFD23F), Color(0xFFFFF6C8)], 'Krilin'),
  ZAttack('makankosappo', 'Makankosappo', [Color(0xFFB06BFF), Color(0xFFFFD23F)], 'Piccolo'),
  ZAttack('masenko', 'Masenko', [Color(0xFFFFC21F), Color(0xFFFFF2B8)], 'Gohan'),
  ZAttack('burning_attack', 'Burning Attack', [Color(0xFFFF8A3D), Color(0xFFFFE066)], 'Trunks'),
  ZAttack('galick_gun', 'Galick Gun', [Color(0xFF8A4DFF), Color(0xFFF2E6FF)], 'Vegeta'),
  ZAttack('kamehameha_instantaneo', 'Kamehameha instantáneo', [Color(0xFF2B8CFF), Color(0xFFDFF4FF)], 'Goku'),
  ZAttack('genkidama', 'Genkidama', [Color(0xFF6FD6FF), Color(0xFFFFFFFF)], 'Kaio-sama'),
  ZAttack('double_sunday', 'Double Sunday', [Color(0xFFB04DFF), Color(0xFFFFC2F0)], 'Raditz'),
  ZAttack('bomber_dx', 'Bomber DX', [Color(0xFFFF6A13), Color(0xFFFFE6A0)], 'Nappa'),
  ZAttack('rayo_mortal', 'Rayo mortal', [Color(0xFFC03DFF), Color(0xFFFFC8F5)], 'Freezer'),
  ZAttack('barrera_explosiva', 'Barrera explosiva', [Color(0xFF45FF8E), Color(0xFFDFFFE9)], 'Androide 17'),
  ZAttack('kamehameha_cell', 'Kamehameha de Cell', [Color(0xFF2ED1A0), Color(0xFFE6FFF6)], 'Cell'),
  ZAttack('explosion_final', 'Explosión final', [Color(0xFFFFD23F), Color(0xFFFFFFFF)], 'Majin Vegeta'),
  ZAttack('rayo_chocolate', 'Rayo chocolate', [Color(0xFFFF5FA8), Color(0xFFFFD6EA)], 'Super Buu'),
  ZAttack('kamehameha_black', 'Kamehameha Black', [Color(0xFFFF4F8B), Color(0xFFFFD6E4)], 'Goku Black'),
];

ZAttack attackById(String? id) => zAttacks.firstWhere((a) => a.id == id, orElse: () => zAttacks.first);
