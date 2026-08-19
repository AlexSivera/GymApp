import 'package:drift/drift.dart';

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
}
