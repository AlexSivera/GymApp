import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/core/constants/muscle_groups.dart';
import 'package:gymapp/data/database/app_database.dart';
import 'package:gymapp/data/seed/exercise_seed_data.dart';
import 'package:gymapp/data/seed/exercise_seeder.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('fresh install gets every seed exercise', () async {
    await syncSeedExercises(db);

    final names = await db.exercisesDao.allNames();
    expect(names.length, exerciseSeedData.length);
    expect(names, containsAll(exerciseSeedData.map((s) => s.name)));
  });

  test('re-running does not duplicate exercises already seeded', () async {
    await syncSeedExercises(db);
    await syncSeedExercises(db);

    expect(await db.exercisesDao.count(), exerciseSeedData.length);
  });

  test('an install that already seeded an older, smaller list gets the new entries added', () async {
    // Simulates an existing user's DB: only the first seed exercise present,
    // as if it was installed before the rest were added to the list.
    final firstSeed = exerciseSeedData.first;
    await db.exercisesDao.insert(ExercisesCompanion.insert(
      name: firstSeed.name,
      primaryMuscles: Value(firstSeed.primaryMuscles),
    ));

    await syncSeedExercises(db);

    final names = await db.exercisesDao.allNames();
    expect(names.length, exerciseSeedData.length, reason: 'missing entries get added');
    expect(await db.exercisesDao.count(), exerciseSeedData.length,
        reason: 'the pre-existing row is not duplicated');
  });

  test('a user-renamed or custom exercise sharing no name with the seed list is left alone', () async {
    await db.exercisesDao.insert(ExercisesCompanion.insert(
      name: 'Mi ejercicio personalizado',
      primaryMuscles: const Value([]),
      isCustom: const Value(true),
    ));

    await syncSeedExercises(db);

    final names = await db.exercisesDao.allNames();
    expect(names, contains('Mi ejercicio personalizado'));
    expect(names.length, exerciseSeedData.length + 1);
  });

  test('every seed exercise only uses muscles from the body diagram taxonomy', () {
    final known = muscleGroups.values.expand((v) => v).toSet();
    for (final seed in exerciseSeedData) {
      expect(known, containsAll([...seed.primaryMuscles, ...seed.secondaryMuscles]), reason: seed.name);
    }
  });

  test('custom exercises with legacy muscle names get renamed without duplicates', () async {
    await db.exercisesDao.insert(ExercisesCompanion.insert(
      name: 'Mi curl de muñeca',
      primaryMuscles: const Value(['Antebrazo']),
      secondaryMuscles: const Value(['Antebrazos', 'Bíceps']),
      isCustom: const Value(true),
    ));
    await db.exercisesDao.insert(ExercisesCompanion.insert(
      name: 'Mi peso muerto',
      primaryMuscles: const Value(['Isquiotibiales']),
      secondaryMuscles: const Value(['Lumbares', 'Abdomen']),
      isCustom: const Value(true),
    ));

    await syncSeedExercises(db);

    final byName = {for (final e in await db.exercisesDao.getAll()) e.name: e};
    expect(byName['Mi curl de muñeca']!.primaryMuscles, ['Antebrazos']);
    expect(byName['Mi curl de muñeca']!.secondaryMuscles, ['Bíceps']);
    expect(byName['Mi peso muerto']!.primaryMuscles, ['Femoral']);
    expect(byName['Mi peso muerto']!.secondaryMuscles, ['Lumbar', 'Abdominales']);
  });
}
