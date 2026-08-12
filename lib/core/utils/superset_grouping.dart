// Maps each superset group id that has 2+ members to a display letter (A,
// B, C...) in first-appearance order — a group of exactly one (the other
// member got removed/reordered away) isn't shown as a superset at all.
// Generic over T so it works for both RoutineExercise and SessionExercise.
Map<int, String> supersetGroupLabels<T>(List<T> items, int? Function(T) groupOf) {
  final counts = <int, int>{};
  for (final item in items) {
    final group = groupOf(item);
    if (group == null) continue;
    counts[group] = (counts[group] ?? 0) + 1;
  }

  final labels = <int, String>{};
  var next = 0;
  for (final item in items) {
    final group = groupOf(item);
    if (group == null || (counts[group] ?? 0) < 2 || labels.containsKey(group)) continue;
    labels[group] = String.fromCharCode(65 + (next % 26));
    next++;
  }
  return labels;
}
