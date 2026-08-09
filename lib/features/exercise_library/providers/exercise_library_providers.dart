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

final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  final exercises = ref.watch(allExercisesProvider).valueOrNull ?? const [];
  final query = ref.watch(exerciseSearchQueryProvider).trim().toLowerCase();
  final muscles = ref.watch(exerciseMuscleFilterProvider);

  return exercises.where((e) {
    final matchesQuery = query.isEmpty || e.name.toLowerCase().contains(query);
    final matchesMuscle = muscles.isEmpty || e.primaryMuscles.any(muscles.contains);
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

final recentExerciseIdsProvider = FutureProvider<List<int>>((ref) {
  return ref.watch(_progressDaoProvider).recentlyUsedExerciseIds();
});

final recentExercisesProvider = Provider<List<Exercise>>((ref) {
  final ids = ref.watch(recentExerciseIdsProvider).valueOrNull ?? const [];
  final byId = {for (final e in ref.watch(allExercisesProvider).valueOrNull ?? const []) e.id: e};
  return [for (final id in ids) if (byId[id] != null) byId[id]!];
});
