import 'package:flutter/material.dart';

// Muscles grouped by body region, in display order — shared by the exercise
// picker's muscle filter and the Rangos screen's muscle list. Any muscle
// present in the data but not listed here (e.g. a custom exercise with a
// made-up muscle name) still shows up, tacked onto "Otros", so nothing gets
// silently hidden.
//
// Exactly the 16 regions of the Rangos body diagram (one or more masks each,
// see lib/features/ranking/widgets/body_diagram.dart). 'Espalda' is the
// mid/upper back (rows); the lats are their own 'Dorsales'.
const muscleGroups = {
  'Tren superior': [
    'Pecho', 'Espalda', 'Dorsales', 'Hombros', 'Bíceps', 'Tríceps', 'Trapecio', 'Antebrazos', 'Cuello',
  ],
  'Tren inferior': ['Cuádriceps', 'Isquiotibiales', 'Glúteos', 'Gemelos', 'Aductores'],
  'Core': ['Abdomen', 'Lumbares'],
};

// Names that older versions of the app let custom exercises use, mapped to
// their current equivalent. Applied to stored exercises on every launch.
const legacyMuscleNames = {
  'Antebrazo': 'Antebrazos',
  'Abductores': 'Glúteos',
};

const _muscleIcons = {
  'Pecho': Icons.fitness_center,
  'Espalda': Icons.rowing,
  'Dorsales': Icons.open_in_full,
  'Hombros': Icons.sports_gymnastics,
  'Bíceps': Icons.front_hand,
  'Tríceps': Icons.back_hand,
  'Trapecio': Icons.expand_less,
  'Antebrazos': Icons.pan_tool_outlined,
  'Cuello': Icons.face_outlined,
  'Abdomen': Icons.self_improvement,
  'Lumbares': Icons.horizontal_rule,
  'Cuádriceps': Icons.directions_run,
  'Isquiotibiales': Icons.directions_walk,
  'Glúteos': Icons.accessibility_new,
  'Gemelos': Icons.bolt,
  'Aductores': Icons.compress,
};

IconData iconForMuscle(String muscle) => _muscleIcons[muscle] ?? Icons.fitness_center;

// Same muscles as [groupedAvailableMuscles], flattened into one list in
// canonical body-region order — used for compact "which muscles does this
// train" summaries (e.g. the Planificar routine cards).
List<String> orderedAvailableMuscles(Iterable<String> available) {
  final remaining = available.toSet();
  final ordered = <String>[];
  for (final group in muscleGroups.values) {
    ordered.addAll(group.where(remaining.remove));
  }
  ordered.addAll(remaining.toList()..sort());
  return ordered;
}

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
