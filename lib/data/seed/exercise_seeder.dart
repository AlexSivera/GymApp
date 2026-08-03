import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'exercise_seed_data.dart';

// Imports the curated exercise list once, only if the table is still empty
// (fresh install). The app never reaches out to any external source again.
Future<void> seedExercisesIfEmpty(AppDatabase db) async {
  final alreadySeeded = await db.exercisesDao.count();
  if (alreadySeeded > 0) return;

  await db.exercisesDao.insertAll([
    for (final seed in exerciseSeedData)
      ExercisesCompanion.insert(
        name: seed.name,
        primaryMuscles: Value(seed.primaryMuscles),
        secondaryMuscles: Value(seed.secondaryMuscles),
        equipment: Value(seed.equipment),
        instructions: Value(seed.instructions),
        imagePaths: Value([seed.imageAsset]),
      ),
  ]);
}
