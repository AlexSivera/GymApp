import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';

final _exercisesDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).exercisesDao,
);

final _progressDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).progressDao,
);

final allExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(_exercisesDaoProvider).watchAll();
});

enum ExerciseViewMode { list, grid }

enum ExerciseLibraryTab { recent, all }

final exerciseViewModeProvider = StateProvider<ExerciseViewMode>((ref) => ExerciseViewMode.list);

final exerciseLibraryTabProvider = StateProvider<ExerciseLibraryTab>((ref) => ExerciseLibraryTab.all);

final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');

final exerciseMuscleFilterProvider = StateProvider<Set<String>>((ref) => {});

// Cardio exercises borrow a muscle (e.g. "Cuádriceps" for running) from the
// source dataset just so they have *a* primaryMuscle, not because filtering
// by that muscle is meaningful — they get their own filter instead of
// cluttering the leg-day muscle groups.
final exerciseCardioOnlyProvider = StateProvider<bool>((ref) => false);

final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  final exercises = ref.watch(allExercisesProvider).valueOrNull ?? const [];
  final query = ref.watch(exerciseSearchQueryProvider).trim().toLowerCase();
  final muscles = ref.watch(exerciseMuscleFilterProvider);
  final cardioOnly = ref.watch(exerciseCardioOnlyProvider);

  return exercises.where((e) {
    final matchesQuery = query.isEmpty || e.name.toLowerCase().contains(query);
    if (!matchesQuery) return false;
    if (cardioOnly) return e.category == ExerciseCategory.cardio;
    if (muscles.isEmpty) return true;
    return e.category != ExerciseCategory.cardio && e.primaryMuscles.any(muscles.contains);
  }).toList();
});

final availableMusclesProvider = Provider<List<String>>((ref) {
  final exercises = ref.watch(allExercisesProvider).valueOrNull ?? const [];
  final muscles = <String>{};
  for (final e in exercises) {
    if (e.category == ExerciseCategory.cardio) continue;
    muscles.addAll(e.primaryMuscles);
  }
  final sorted = muscles.toList()..sort();
  return sorted;
});

final recentExerciseIdsProvider = FutureProvider<List<int>>((ref) {
  return ref.watch(_progressDaoProvider).recentlyUsedExerciseIds();
});

final recentExercisesProvider = Provider<List<Exercise>>((ref) {
  final ids = ref.watch(recentExerciseIdsProvider).valueOrNull ?? const [];
  final byId = {for (final e in ref.watch(allExercisesProvider).valueOrNull ?? const []) e.id: e};
  return [for (final id in ids) if (byId[id] != null) byId[id]!];
});
