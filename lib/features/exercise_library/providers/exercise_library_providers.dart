import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';

final _exercisesDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).exercisesDao,
);

final allExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(_exercisesDaoProvider).watchAll();
});

final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');

final exerciseMuscleFilterProvider = StateProvider<String?>((ref) => null);

final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  final exercises = ref.watch(allExercisesProvider).valueOrNull ?? const [];
  final query = ref.watch(exerciseSearchQueryProvider).trim().toLowerCase();
  final muscle = ref.watch(exerciseMuscleFilterProvider);

  return exercises.where((e) {
    final matchesQuery = query.isEmpty || e.name.toLowerCase().contains(query);
    final matchesMuscle = muscle == null || e.primaryMuscles.contains(muscle);
    return matchesQuery && matchesMuscle;
  }).toList();
});

final availableMusclesProvider = Provider<List<String>>((ref) {
  final exercises = ref.watch(allExercisesProvider).valueOrNull ?? const [];
  final muscles = <String>{};
  for (final e in exercises) {
    muscles.addAll(e.primaryMuscles);
  }
  final sorted = muscles.toList()..sort();
  return sorted;
});
