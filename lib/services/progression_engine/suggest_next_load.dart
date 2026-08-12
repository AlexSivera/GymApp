import '../../core/utils/weight_unit.dart';
import '../../data/database/app_database.dart';

class LoadSuggestion {
  const LoadSuggestion({required this.message, this.suggestedWeight});

  final String message;
  final double? suggestedWeight;
}

// Simple double-progression heuristic:
// - If every set from last time reached the top of the rep range, suggest
//   bumping the weight up.
// - If any set fell short of the bottom of the range, suggest holding the
//   same weight until reps improve.
// - Otherwise, encourage adding a rep or two at the same weight.
LoadSuggestion suggestNextLoad({
  required List<WorkoutSet> previousSets,
  required int targetRepsMin,
  required int targetRepsMax,
  double weightIncrement = 2.5,
  WeightUnit unit = WeightUnit.kg,
}) {
  final validSets =
      previousSets.where((s) => s.weightKg != null && s.reps != null && !s.isWarmup).toList();

  if (validSets.isEmpty) {
    return const LoadSuggestion(message: 'Sin datos de la última vez.');
  }

  final lastWeight = validSets.last.weightKg!;
  final allAtTop = validSets.every((s) => s.reps! >= targetRepsMax);
  final anyBelowMin = validSets.any((s) => s.reps! < targetRepsMin);

  if (allAtTop) {
    final next = lastWeight + weightIncrement;
    return LoadSuggestion(
      message: 'Completaste el rango superior. Prueba con ${formatWeight(next, unit)}.',
      suggestedWeight: next,
    );
  }
  if (anyBelowMin) {
    return LoadSuggestion(
      message: 'Mantén ${formatWeight(lastWeight, unit)} hasta consolidar más repeticiones.',
      suggestedWeight: lastWeight,
    );
  }
  return LoadSuggestion(
    message: 'Vas bien con ${formatWeight(lastWeight, unit)}. Intenta sumar alguna repetición más.',
    suggestedWeight: lastWeight,
  );
}
