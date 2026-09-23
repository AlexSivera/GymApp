import 'package:flutter/material.dart';

// Muscles grouped the way the Rangos screen shows them, in display order:
// three expandable groups, then four standalone muscles (a group of one).
// Shared by the exercise picker's muscle filter, the create-exercise muscle
// chooser and the Rangos muscle list. Any muscle present in the data but not
// listed here (e.g. a custom exercise with a made-up muscle name) still shows
// up, tacked onto "Otros", so nothing gets silently hidden.
//
// Every muscle except 'Abductores' has its own region in the body
// illustration (see lib/features/ranking/widgets/body_masks.dart). 'Espalda'
// is the mid/upper back (rows); the lats are their own 'Dorsales'.
const muscleGroups = {
  'Brazos': ['Tríceps', 'Bíceps', 'Antebrazos'],
  'Piernas': ['Cuádriceps', 'Glúteos', 'Gemelos', 'Aductores', 'Femoral', 'Abductores'],
  'Espalda': ['Espalda', 'Lumbar', 'Dorsales', 'Trapecio'],
  'Pecho': ['Pecho'],
  'Hombros': ['Hombros'],
  'Abdominales': ['Abdominales'],
  'Cuello': ['Cuello'],
};

// Names that older versions of the app used, mapped to their current
// equivalent. Applied to stored exercises on every launch.
const legacyMuscleNames = {
  'Antebrazo': 'Antebrazos',
  'Isquiotibiales': 'Femoral',
  'Lumbares': 'Lumbar',
  'Abdomen': 'Abdominales',
};

const _muscleIcons = {
  'Pecho': Icons.fitness_center,
  'Espalda': Icons.rowing,
  'Dorsales': Icons.open_in_full,
  'Lumbar': Icons.horizontal_rule,
  'Trapecio': Icons.expand_less,
  'Hombros': Icons.sports_gymnastics,
  'Bíceps': Icons.front_hand,
  'Tríceps': Icons.back_hand,
  'Antebrazos': Icons.pan_tool_outlined,
  'Cuello': Icons.face_outlined,
  'Abdominales': Icons.self_improvement,
  'Cuádriceps': Icons.directions_run,
  'Femoral': Icons.directions_walk,
  'Glúteos': Icons.accessibility_new,
  'Gemelos': Icons.bolt,
  'Aductores': Icons.compress,
  'Abductores': Icons.swap_horiz,
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

// [groupedAvailableMuscles] for chip/tile pickers: the standalone muscles
// are pooled under one heading, so a picker never shows a "Pecho" header
// over a lone "Pecho" chip.
Map<String, List<String>> groupedMusclesForPicker(List<String> available) {
  final result = <String, List<String>>{};
  final standalone = <String>[];
  for (final MapEntry(key: group, value: muscles) in groupedAvailableMuscles(available).entries) {
    if (muscleGroups[group]?.length == 1) {
      standalone.addAll(muscles);
    } else {
      if (group == 'Otros' && standalone.isNotEmpty) result['Torso y cuello'] = [...standalone];
      result[group] = muscles;
    }
  }
  if (standalone.isNotEmpty) result.putIfAbsent('Torso y cuello', () => standalone);
  return result;
}
