import 'package:flutter/material.dart';

// Muscles grouped by body region, in display order — shared by the exercise
// picker's muscle filter and the Rangos screen's muscle list. Any muscle
// present in the data but not listed here (e.g. a custom exercise with a
// made-up muscle name) still shows up, tacked onto "Otros", so nothing gets
// silently hidden.
const muscleGroups = {
  'Tren superior': ['Pecho', 'Espalda', 'Hombros', 'Bíceps', 'Tríceps'],
  'Tren inferior': ['Cuádriceps', 'Isquiotibiales', 'Glúteos', 'Gemelos'],
  'Core': ['Abdomen'],
};

const _muscleIcons = {
  'Pecho': Icons.fitness_center,
  'Espalda': Icons.rowing,
  'Hombros': Icons.sports_gymnastics,
  'Bíceps': Icons.front_hand,
  'Tríceps': Icons.back_hand,
  'Abdomen': Icons.self_improvement,
  'Cuádriceps': Icons.directions_run,
  'Isquiotibiales': Icons.directions_walk,
  'Glúteos': Icons.accessibility_new,
  'Gemelos': Icons.bolt,
};

IconData iconForMuscle(String muscle) => _muscleIcons[muscle] ?? Icons.fitness_center;

// Same grouping as above, but only the muscles actually present in
// [available], with any unrecognized ones appended under "Otros".
Map<String, List<String>> groupedAvailableMuscles(List<String> available) {
  final remaining = available.toSet();
  final grouped = <String, List<String>>{};
  for (final entry in muscleGroups.entries) {
    final present = entry.value.where(remaining.remove).toList();
    if (present.isNotEmpty) grouped[entry.key] = present;
  }
  if (remaining.isNotEmpty) grouped['Otros'] = remaining.toList()..sort();
  return grouped;
}
