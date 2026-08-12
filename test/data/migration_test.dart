import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/data/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  test('v1 -> v5 migration preserves existing rows and adds the new columns', () async {
    final tempDir = Directory.systemTemp.createTempSync('gymapp_migration_test_v1');
    final dbPath = p.join(tempDir.path, 'v1.sqlite');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    // Hand-build the parts of the v1 schema later migrations touch, with one
    // real row in each, so we can assert the upgrade doesn't drop data.
    final seed = sqlite3.sqlite3.open(dbPath);
    seed.execute('''
      CREATE TABLE exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
      CREATE TABLE workout_sessions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        routine_day_id INTEGER,
        status INTEGER NOT NULL DEFAULT 0,
        started_at INTEGER,
        completed_at INTEGER,
        duration_seconds INTEGER,
        body_weight_kg REAL,
        feeling INTEGER,
        notes TEXT
      );
      CREATE TABLE session_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        workout_session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        notes TEXT
      );
      CREATE TABLE user_settings (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        units TEXT NOT NULL DEFAULT 'kg',
        name TEXT,
        goals TEXT
      );
      CREATE TABLE routines (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
      CREATE TABLE routine_days (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        routine_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        day_order INTEGER NOT NULL
      );
      CREATE TABLE routine_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        routine_day_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        target_sets INTEGER NOT NULL,
        target_reps_min INTEGER NOT NULL,
        target_reps_max INTEGER NOT NULL,
        target_rir INTEGER,
        rest_seconds INTEGER,
        notes TEXT
      );
      CREATE TABLE workout_sets (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        session_exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL,
        reps INTEGER
      );
      INSERT INTO exercises (id, name) VALUES (1, 'Press banca');
      INSERT INTO workout_sessions (id, date, status) VALUES (1, 1690000000000, 2);
      INSERT INTO session_exercises (id, workout_session_id, exercise_id, order_index, notes)
        VALUES (1, 1, 1, 0, 'existing note');
      INSERT INTO user_settings (id, units, name, goals) VALUES (1, 'kg', 'Alex', NULL);
      INSERT INTO routines (id, name) VALUES (1, 'Full Body');
      INSERT INTO routine_days (id, routine_id, name, day_order) VALUES (1, 1, 'Día 1', 0);
      INSERT INTO routine_exercises
        (id, routine_day_id, exercise_id, order_index, target_sets, target_reps_min, target_reps_max)
        VALUES (1, 1, 1, 0, 3, 8, 12);
      PRAGMA user_version = 1;
    ''');
    seed.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final sessionExercise =
        await (db.select(db.sessionExercises)..where((e) => e.id.equals(1))).getSingle();
    expect(sessionExercise.notes, 'existing note');
    expect(sessionExercise.status, SessionExerciseStatus.pending, reason: 'new column gets its default');

    final settings = await (db.select(db.userSettings)..where((s) => s.id.equals(1))).getSingle();
    expect(settings.name, 'Alex', reason: 'pre-existing row survives the upgrade');
    expect(settings.weeklyTargetSessions, 4, reason: 'new column gets its default');
    expect(settings.gender, isNull, reason: 'new column defaults to null');
    expect(settings.birthDate, isNull, reason: 'new column defaults to null');
    expect(settings.onboardingCompleted, isFalse, reason: 'new column gets its default');

    final routineExercise =
        await (db.select(db.routineExercises)..where((e) => e.id.equals(1))).getSingle();
    expect(routineExercise.targetSets, 3, reason: 'pre-existing row survives the upgrade');
    expect(routineExercise.targetWeight, isNull, reason: 'new column defaults to null');

    final favoriteTableExists = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type='table' AND name='favorite_exercises'")
        .get();
    expect(favoriteTableExists, isEmpty, reason: 'favorite_exercises was removed in v3');
  });

  test('v2 -> v3 migration drops favorite_exercises and adds target_weight', () async {
    final tempDir = Directory.systemTemp.createTempSync('gymapp_migration_test_v2');
    final dbPath = p.join(tempDir.path, 'v2.sqlite');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    // Minimal v2 shape: routine_exercises without target_weight yet, plus
    // the favorite_exercises table (with a real row) that v3 removes.
    final seed = sqlite3.sqlite3.open(dbPath);
    seed.execute('''
      CREATE TABLE exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
      CREATE TABLE routines (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
      CREATE TABLE routine_days (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        routine_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        day_order INTEGER NOT NULL
      );
      CREATE TABLE routine_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        routine_day_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        target_sets INTEGER NOT NULL,
        target_reps_min INTEGER NOT NULL,
        target_reps_max INTEGER NOT NULL,
        target_rir INTEGER,
        rest_seconds INTEGER,
        notes TEXT
      );
      CREATE TABLE favorite_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL UNIQUE
      );
      CREATE TABLE user_settings (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        units TEXT NOT NULL DEFAULT 'kg',
        name TEXT,
        goals TEXT,
        weekly_target_sessions INTEGER NOT NULL DEFAULT 4
      );
      CREATE TABLE session_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        workout_session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      );
      CREATE TABLE workout_sets (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        session_exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL,
        reps INTEGER
      );
      INSERT INTO exercises (id, name) VALUES (1, 'Press banca');
      INSERT INTO routines (id, name) VALUES (1, 'Full Body');
      INSERT INTO routine_days (id, routine_id, name, day_order) VALUES (1, 1, 'Día 1', 0);
      INSERT INTO routine_exercises
        (id, routine_day_id, exercise_id, order_index, target_sets, target_reps_min, target_reps_max)
        VALUES (1, 1, 1, 0, 4, 6, 10);
      INSERT INTO favorite_exercises (id, exercise_id) VALUES (1, 1);
      INSERT INTO user_settings (id, units, name, goals) VALUES (1, 'kg', NULL, NULL);
      PRAGMA user_version = 2;
    ''');
    seed.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final routineExercise =
        await (db.select(db.routineExercises)..where((e) => e.id.equals(1))).getSingle();
    expect(routineExercise.targetSets, 4, reason: 'pre-existing row survives the upgrade');
    expect(routineExercise.targetWeight, isNull, reason: 'new column defaults to null');

    final favoriteTableExists = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type='table' AND name='favorite_exercises'")
        .get();
    expect(favoriteTableExists, isEmpty, reason: 'favorite_exercises should be dropped');
  });

  test('v3 -> v4 migration adds gender/birth_date/onboarding_completed', () async {
    final tempDir = Directory.systemTemp.createTempSync('gymapp_migration_test_v3');
    final dbPath = p.join(tempDir.path, 'v3.sqlite');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    // Minimal v3 shape: user_settings without the onboarding columns yet.
    // exercises/workout_sets are included too even though this test doesn't
    // assert on them — later migrations (v6) alter both, so every fixture
    // needs to have them regardless of which columns the test itself checks.
    final seed = sqlite3.sqlite3.open(dbPath);
    seed.execute('''
      CREATE TABLE user_settings (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        units TEXT NOT NULL DEFAULT 'kg',
        name TEXT,
        goals TEXT,
        weekly_target_sessions INTEGER NOT NULL DEFAULT 4
      );
      CREATE TABLE exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
      CREATE TABLE workout_sets (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        session_exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL,
        reps INTEGER
      );
      CREATE TABLE routine_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        routine_day_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        target_sets INTEGER NOT NULL,
        target_reps_min INTEGER NOT NULL,
        target_reps_max INTEGER NOT NULL,
        target_weight REAL,
        target_rir INTEGER,
        rest_seconds INTEGER,
        notes TEXT
      );
      CREATE TABLE session_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        workout_session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      );
      INSERT INTO user_settings (id, units, name, goals) VALUES (1, 'kg', 'Alex', NULL);
      PRAGMA user_version = 3;
    ''');
    seed.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final settings = await (db.select(db.userSettings)..where((s) => s.id.equals(1))).getSingle();
    expect(settings.name, 'Alex', reason: 'pre-existing row survives the upgrade');
    expect(settings.gender, isNull, reason: 'new column defaults to null');
    expect(settings.birthDate, isNull, reason: 'new column defaults to null');
    expect(settings.onboardingCompleted, isFalse, reason: 'new column gets its default');
  });

  test('v4 -> v5 migration creates exercise_rank_acknowledgements', () async {
    final tempDir = Directory.systemTemp.createTempSync('gymapp_migration_test_v4');
    final dbPath = p.join(tempDir.path, 'v4.sqlite');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    // Minimal v4 shape: just enough to open at user_version 4.
    final seed = sqlite3.sqlite3.open(dbPath);
    seed.execute('''
      CREATE TABLE exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
      CREATE TABLE workout_sets (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        session_exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL,
        reps INTEGER
      );
      CREATE TABLE routine_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        routine_day_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        target_sets INTEGER NOT NULL,
        target_reps_min INTEGER NOT NULL,
        target_reps_max INTEGER NOT NULL,
        target_weight REAL,
        target_rir INTEGER,
        rest_seconds INTEGER,
        notes TEXT
      );
      CREATE TABLE session_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        workout_session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      );
      CREATE TABLE user_settings (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        units TEXT NOT NULL DEFAULT 'kg',
        name TEXT,
        goals TEXT,
        weekly_target_sessions INTEGER NOT NULL DEFAULT 4,
        gender TEXT,
        birth_date INTEGER,
        onboarding_completed INTEGER NOT NULL DEFAULT 0
      );
      INSERT INTO exercises (id, name) VALUES (1, 'Press banca');
      PRAGMA user_version = 4;
    ''');
    seed.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final tableExists = await db
        .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='exercise_rank_acknowledgements'")
        .get();
    expect(tableExists, isNotEmpty, reason: 'exercise_rank_acknowledgements should be created');

    // The table should be usable — insert and read back a row.
    await db.rankingDao.acknowledge(1, 2, 3);
    final rows = await db.rankingDao.watchAcknowledged().first;
    expect(rows, hasLength(1));
    expect(rows.first.tierIndex, 2);
    expect(rows.first.subTier, 3);
  });

  test('v5 -> v6 migration adds exercise category and set duration/distance', () async {
    final tempDir = Directory.systemTemp.createTempSync('gymapp_migration_test_v5');
    final dbPath = p.join(tempDir.path, 'v5.sqlite');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    // Minimal v5 shape: exercises without `category`, workout_sets without
    // `duration_seconds`/`distance_meters`.
    final seed = sqlite3.sqlite3.open(dbPath);
    seed.execute('''
      CREATE TABLE exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        primary_muscles TEXT NOT NULL DEFAULT '[]',
        secondary_muscles TEXT NOT NULL DEFAULT '[]',
        equipment TEXT,
        image_paths TEXT NOT NULL DEFAULT '[]',
        video_url TEXT,
        instructions TEXT,
        is_custom INTEGER NOT NULL DEFAULT 0,
        external_id TEXT,
        created_at INTEGER NOT NULL DEFAULT 0
      );
      CREATE TABLE workout_sessions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        status INTEGER NOT NULL DEFAULT 0
      );
      CREATE TABLE session_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        workout_session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        status INTEGER NOT NULL DEFAULT 0
      );
      CREATE TABLE workout_sets (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        session_exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL,
        reps INTEGER,
        rir REAL,
        is_warmup INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at INTEGER
      );
      CREATE TABLE routine_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        routine_day_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        target_sets INTEGER NOT NULL,
        target_reps_min INTEGER NOT NULL,
        target_reps_max INTEGER NOT NULL,
        target_weight REAL,
        target_rir INTEGER,
        rest_seconds INTEGER,
        notes TEXT
      );
      CREATE TABLE user_settings (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        units TEXT NOT NULL DEFAULT 'kg',
        name TEXT,
        goals TEXT,
        weekly_target_sessions INTEGER NOT NULL DEFAULT 4,
        gender TEXT,
        birth_date INTEGER,
        onboarding_completed INTEGER NOT NULL DEFAULT 0
      );
      INSERT INTO exercises (id, name) VALUES (1, 'Press banca');
      INSERT INTO workout_sessions (id, date, status) VALUES (1, 1690000000000, 2);
      INSERT INTO session_exercises (id, workout_session_id, exercise_id, order_index)
        VALUES (1, 1, 1, 0);
      INSERT INTO workout_sets (id, session_exercise_id, set_number, weight_kg, reps)
        VALUES (1, 1, 1, 80, 8);
      PRAGMA user_version = 5;
    ''');
    seed.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final exercise = await (db.select(db.exercises)..where((e) => e.id.equals(1))).getSingle();
    expect(exercise.name, 'Press banca', reason: 'pre-existing row survives the upgrade');
    expect(exercise.category, ExerciseCategory.strength, reason: 'new column gets its default');

    final set = await (db.select(db.workoutSets)..where((s) => s.id.equals(1))).getSingle();
    expect(set.weightKg, 80, reason: 'pre-existing row survives the upgrade');
    expect(set.durationSeconds, isNull, reason: 'new column defaults to null');
    expect(set.distanceMeters, isNull, reason: 'new column defaults to null');
  });

  test('v6 -> v7 migration adds reminders_enabled', () async {
    final tempDir = Directory.systemTemp.createTempSync('gymapp_migration_test_v6');
    final dbPath = p.join(tempDir.path, 'v6.sqlite');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    // Minimal v6 shape: user_settings without reminders_enabled yet.
    final seed = sqlite3.sqlite3.open(dbPath);
    seed.execute('''
      CREATE TABLE user_settings (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        units TEXT NOT NULL DEFAULT 'kg',
        name TEXT,
        goals TEXT,
        weekly_target_sessions INTEGER NOT NULL DEFAULT 4,
        gender TEXT,
        birth_date INTEGER,
        onboarding_completed INTEGER NOT NULL DEFAULT 0
      );
      CREATE TABLE exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        primary_muscles TEXT NOT NULL DEFAULT '[]',
        secondary_muscles TEXT NOT NULL DEFAULT '[]',
        equipment TEXT,
        category INTEGER NOT NULL DEFAULT 0,
        image_paths TEXT NOT NULL DEFAULT '[]',
        video_url TEXT,
        instructions TEXT,
        is_custom INTEGER NOT NULL DEFAULT 0,
        external_id TEXT,
        created_at INTEGER NOT NULL DEFAULT 0
      );
      CREATE TABLE workout_sets (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        session_exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL,
        reps INTEGER,
        rir REAL,
        duration_seconds INTEGER,
        distance_meters REAL,
        is_warmup INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at INTEGER
      );
      CREATE TABLE routine_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        routine_day_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        target_sets INTEGER NOT NULL,
        target_reps_min INTEGER NOT NULL,
        target_reps_max INTEGER NOT NULL,
        target_weight REAL,
        target_rir INTEGER,
        rest_seconds INTEGER,
        notes TEXT
      );
      CREATE TABLE session_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        workout_session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      );
      INSERT INTO user_settings (id, units, name, goals) VALUES (1, 'kg', 'Alex', NULL);
      PRAGMA user_version = 6;
    ''');
    seed.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final settings = await (db.select(db.userSettings)..where((s) => s.id.equals(1))).getSingle();
    expect(settings.name, 'Alex', reason: 'pre-existing row survives the upgrade');
    expect(settings.remindersEnabled, isTrue, reason: 'new column defaults to true');
  });

  test('v7 -> v8 migration adds superset_group to routine/session exercises', () async {
    final tempDir = Directory.systemTemp.createTempSync('gymapp_migration_test_v7');
    final dbPath = p.join(tempDir.path, 'v7.sqlite');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    // Minimal v7 shape: routine_exercises/session_exercises without
    // superset_group yet.
    final seed = sqlite3.sqlite3.open(dbPath);
    seed.execute('''
      CREATE TABLE exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        primary_muscles TEXT NOT NULL DEFAULT '[]',
        secondary_muscles TEXT NOT NULL DEFAULT '[]',
        equipment TEXT,
        category INTEGER NOT NULL DEFAULT 0,
        image_paths TEXT NOT NULL DEFAULT '[]',
        video_url TEXT,
        instructions TEXT,
        is_custom INTEGER NOT NULL DEFAULT 0,
        external_id TEXT,
        created_at INTEGER NOT NULL DEFAULT 0
      );
      CREATE TABLE workout_sessions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        status INTEGER NOT NULL DEFAULT 0
      );
      CREATE TABLE session_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        workout_session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      );
      CREATE TABLE workout_sets (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        session_exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL,
        reps INTEGER,
        rir REAL,
        duration_seconds INTEGER,
        distance_meters REAL,
        is_warmup INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at INTEGER
      );
      CREATE TABLE routine_exercises (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        routine_day_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        target_sets INTEGER NOT NULL,
        target_reps_min INTEGER NOT NULL,
        target_reps_max INTEGER NOT NULL,
        target_weight REAL,
        target_rir INTEGER,
        rest_seconds INTEGER,
        notes TEXT
      );
      CREATE TABLE user_settings (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        units TEXT NOT NULL DEFAULT 'kg',
        name TEXT,
        goals TEXT,
        weekly_target_sessions INTEGER NOT NULL DEFAULT 4,
        gender TEXT,
        birth_date INTEGER,
        onboarding_completed INTEGER NOT NULL DEFAULT 0,
        reminders_enabled INTEGER NOT NULL DEFAULT 1
      );
      INSERT INTO exercises (id, name) VALUES (1, 'Press banca');
      INSERT INTO workout_sessions (id, date, status) VALUES (1, 1690000000000, 2);
      INSERT INTO session_exercises (id, workout_session_id, exercise_id, order_index)
        VALUES (1, 1, 1, 0);
      INSERT INTO routine_exercises
        (id, routine_day_id, exercise_id, order_index, target_sets, target_reps_min, target_reps_max)
        VALUES (1, 1, 1, 0, 3, 8, 12);
      PRAGMA user_version = 7;
    ''');
    seed.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final sessionExercise =
        await (db.select(db.sessionExercises)..where((e) => e.id.equals(1))).getSingle();
    expect(sessionExercise.exerciseId, 1, reason: 'pre-existing row survives the upgrade');
    expect(sessionExercise.supersetGroup, isNull, reason: 'new column defaults to null');

    final routineExercise =
        await (db.select(db.routineExercises)..where((e) => e.id.equals(1))).getSingle();
    expect(routineExercise.targetSets, 3, reason: 'pre-existing row survives the upgrade');
    expect(routineExercise.supersetGroup, isNull, reason: 'new column defaults to null');
  });
}
