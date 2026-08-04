import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/data/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  test('v1 -> v2 migration preserves existing rows and adds the new columns/table', () async {
    final tempDir = Directory.systemTemp.createTempSync('gymapp_migration_test');
    final dbPath = p.join(tempDir.path, 'v1.sqlite');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    // Hand-build the parts of the v1 schema the v2 migration touches, with
    // one real row in each, so we can assert the upgrade doesn't drop data.
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
      INSERT INTO exercises (id, name) VALUES (1, 'Press banca');
      INSERT INTO workout_sessions (id, date, status) VALUES (1, 1690000000000, 2);
      INSERT INTO session_exercises (id, workout_session_id, exercise_id, order_index, notes)
        VALUES (1, 1, 1, 0, 'existing note');
      INSERT INTO user_settings (id, units, name, goals) VALUES (1, 'kg', 'Alex', NULL);
      PRAGMA user_version = 1;
    ''');
    seed.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final sessionExercise = await (db.select(db.sessionExercises)
          ..where((e) => e.id.equals(1)))
        .getSingle();
    expect(sessionExercise.notes, 'existing note');
    expect(sessionExercise.status, SessionExerciseStatus.pending, reason: 'new column gets its default');

    final settings = await (db.select(db.userSettings)..where((s) => s.id.equals(1))).getSingle();
    expect(settings.name, 'Alex', reason: 'pre-existing row survives the upgrade');
    expect(settings.weeklyTargetSessions, 4, reason: 'new column gets its default');

    // The new table exists and is usable post-migration.
    final favoriteId = await db.favoritesDao
        .toggleFavorite(1)
        .then((_) => db.select(db.favoriteExercises).getSingle())
        .then((row) => row.id);
    expect(favoriteId, isNotNull);
  });
}
