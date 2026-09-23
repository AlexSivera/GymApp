import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show listEquals;

import '../../core/constants/muscle_groups.dart';
import '../database/app_database.dart';
import 'exercise_seed_data.dart';

// Imports the bundled exercise list, inserting entries not already present
// (matched by name — the only stable identity the original rows have,
// since externalId wasn't recorded when they were first seeded) and
// refreshing the fields of ones that are, so that switching the bundled
// data source (e.g. free-exercise-db -> ExerciseDB) or editing an entry's
// muscles/image in exerciseSeedData reaches installs that already seeded
// an earlier version. Runs on every launch — a no-op once nothing changed.
Future<void> syncSeedExercises(AppDatabase db) async {
  final existingNames = await db.exercisesDao.allNames();

  final entries = [
    for (final seed in exerciseSeedData)
      if (!existingNames.contains(seed.name))
        ExercisesCompanion.insert(
          name: seed.name,
          primaryMuscles: Value(seed.primaryMuscles),
          secondaryMuscles: Value(seed.secondaryMuscles),
          equipment: Value(seed.equipment),
          category: Value(seed.category),
          instructions: Value(seed.instructions),
          imagePaths: Value([seed.imageAsset]),
        ),
  ];
  if (entries.isNotEmpty) await db.exercisesDao.insertAll(entries);

  for (final seed in exerciseSeedData) {
    if (!existingNames.contains(seed.name)) continue;
    await db.exercisesDao.updateSeedFields(
      seed.name,
      ExercisesCompanion(
        primaryMuscles: Value(seed.primaryMuscles),
        secondaryMuscles: Value(seed.secondaryMuscles),
        equipment: Value(seed.equipment),
        category: Value(seed.category),
        instructions: Value(seed.instructions),
        imagePaths: Value([seed.imageAsset]),
      ),
    );
  }

  await _renameLegacyMuscles(db);
}

// Custom exercises keep whatever muscle names the picker offered when they
// were created; rename the ones that no longer exist (see legacyMuscleNames)
// so they still show up under the right muscle in Rangos and the filters.
Future<void> _renameLegacyMuscles(AppDatabase db) async {
  List<String> rename(List<String> muscles) =>
      [...{for (final m in muscles) legacyMuscleNames[m] ?? m}];

  for (final exercise in await db.exercisesDao.getAll()) {
    final primary = rename(exercise.primaryMuscles);
    final secondary = [for (final m in rename(exercise.secondaryMuscles)) if (!primary.contains(m)) m];
    if (listEquals(primary, exercise.primaryMuscles) && listEquals(secondary, exercise.secondaryMuscles)) {
      continue;
    }
    await db.exercisesDao.updateMuscles(exercise.id, primary, secondary);
  }
}
