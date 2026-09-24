import 'weight_unit.dart';

// One way of writing a strength set everywhere in the app — "15 kg × 12" —
// instead of the "15×12 kg" / "10×12" / "15kg×12" variants different screens
// used to each build on their own. Non-breaking spaces keep a set from
// wrapping in the middle ("15 kg" on one line and "× 12" on the next).
const _nbsp = '\u00A0';

String formatStrengthSet(double weightKg, int reps, WeightUnit unit) =>
    '${formatWeightValue(weightKg, unit)}$_nbsp${weightUnitLabel(unit)}$_nbsp×$_nbsp$reps';

// Several sets in one short line: "3 series de 15 kg × 12" when they're all
// the same (the common case), otherwise "3 series · mejor 30 kg × 12" — the
// heaviest one — so the line stays short enough not to wrap.
String summarizeStrengthSets(List<({double weightKg, int reps})> sets, WeightUnit unit) {
  if (sets.isEmpty) return '';
  final first = sets.first;
  if (sets.length == 1) return formatStrengthSet(first.weightKg, first.reps, unit);
  final allSame = sets.every((s) => s.weightKg == first.weightKg && s.reps == first.reps);
  if (allSame) return '${sets.length} series de ${formatStrengthSet(first.weightKg, first.reps, unit)}';
  final best = sets.reduce((a, b) =>
      b.weightKg > a.weightKg || (b.weightKg == a.weightKg && b.reps > a.reps) ? b : a);
  return '${sets.length} series · mejor ${formatStrengthSet(best.weightKg, best.reps, unit)}';
}

// "1 h 05 min" / "42 min" / "45 s" — for session durations.
String formatSessionDuration(int seconds) {
  if (seconds < 60) return '$seconds${_nbsp}s';
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours == 0) return '$minutes${_nbsp}min';
  return '$hours${_nbsp}h ${minutes.toString().padLeft(2, '0')}${_nbsp}min';
}
