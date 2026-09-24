import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/core/utils/set_format.dart';
import 'package:gymapp/core/utils/weight_unit.dart';

// Non-breaking spaces are part of the format (they keep "15 kg × 12" on one
// line); compare against plain spaces for readability.
String plain(String s) => s.replaceAll(' ', ' ');

void main() {
  test('one set is written as weight, unit, then reps', () {
    expect(plain(formatStrengthSet(15, 12, WeightUnit.kg)), '15 kg × 12');
    expect(plain(formatStrengthSet(12.5, 8, WeightUnit.kg)), '12.5 kg × 8');
  });

  test('identical sets collapse into "N series de ..."', () {
    final sets = [for (var i = 0; i < 3; i++) (weightKg: 20.0, reps: 12)];
    expect(plain(summarizeStrengthSets(sets, WeightUnit.kg)), '3 series de 20 kg × 12');
  });

  test('different sets show the count and the heaviest one', () {
    final sets = [(weightKg: 25.0, reps: 12), (weightKg: 30.0, reps: 10), (weightKg: 27.5, reps: 12)];
    expect(plain(summarizeStrengthSets(sets, WeightUnit.kg)), '3 series · mejor 30 kg × 10');
  });

  test('session durations', () {
    expect(plain(formatSessionDuration(45)), '45 s');
    expect(plain(formatSessionDuration(42 * 60 + 10)), '42 min');
    expect(plain(formatSessionDuration(3600 + 5 * 60)), '1 h 05 min');
  });
}
