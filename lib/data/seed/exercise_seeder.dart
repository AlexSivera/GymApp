import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'exercise_seed_data.dart';

// Imports the bundled exercise list, inserting only the entries not already
// present (matched by name — the only stable identity the original rows
// have, since externalId wasn't recorded when they were first seeded).
// Runs on every launch instead of "only if empty" so that exercises added
// to exerciseSeedData in an app update actually reach installs that already
// seeded an earlier, smaller list — a no-op query once nothing's missing.
Future<void> syncSeedExercises(AppDatabase db) async {
  final existingNames = await db.exercisesDao.allNames();
  final missing = exerciseSeedData.where((seed) => !existingNames.contains(seed.name));

  final entries = [
    for (final seed in missing)
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
}
