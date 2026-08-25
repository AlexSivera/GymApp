import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'converters.dart';
import 'daos/body_weight_dao.dart';
import 'daos/exercises_dao.dart';
import 'daos/personal_records_dao.dart';
import 'daos/progress_dao.dart';
import 'daos/ranking_dao.dart';
import 'daos/routines_dao.dart';
import 'daos/session_logging_dao.dart';
import 'daos/user_settings_dao.dart';
import 'daos/workout_sessions_dao.dart';
import 'enums.dart';
import 'tables/body_weight_logs_table.dart';
import 'tables/exercise_rank_acknowledgements_table.dart';
import 'tables/exercises_table.dart';
import 'tables/personal_records_table.dart';
import 'tables/routines_table.dart';
import 'tables/user_settings_table.dart';
import 'tables/workout_sessions_table.dart';

export 'converters.dart';
export 'enums.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Exercises,
  Routines,
  RoutineDays,
  RoutineExercises,
  WorkoutSessions,
  SessionExercises,
  WorkoutSets,
  PersonalRecords,
  BodyWeightLogs,
  UserSettings,
  ExerciseRankAcknowledgements,
], daos: [
  WorkoutSessionsDao,
  BodyWeightDao,
  ExercisesDao,
  RoutinesDao,
  SessionLoggingDao,
  PersonalRecordsDao,
  ProgressDao,
  UserSettingsDao,
  RankingDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(sessionExercises, sessionExercises.status);
            await m.addColumn(userSettings, userSettings.weeklyTargetSessions);
            // v2 also introduced a `favorite_exercises` table, later dropped
            // in v3 — intentionally not created here so upgraders never
            // build a table only to remove it a step later.
          }
          if (from < 3) {
            await m.addColumn(routineExercises, routineExercises.targetWeight);
            // Drops the table from schema v2 installs; a no-op for anyone
            // jumping straight from v1.
            await m.database.customStatement('DROP TABLE IF EXISTS favorite_exercises');
          }
          if (from < 4) {
            await m.addColumn(userSettings, userSettings.gender);
            await m.addColumn(userSettings, userSettings.birthDate);
            await m.addColumn(userSettings, userSettings.onboardingCompleted);
          }
          if (from < 5) {
            await m.createTable(exerciseRankAcknowledgements);
          }
          if (from < 6) {
            await m.addColumn(exercises, exercises.category);
            await m.addColumn(workoutSets, workoutSets.durationSeconds);
            await m.addColumn(workoutSets, workoutSets.distanceMeters);
          }
          if (from < 7) {
            await m.addColumn(userSettings, userSettings.remindersEnabled);
          }
          if (from < 8) {
            await m.addColumn(routineExercises, routineExercises.supersetGroup);
            await m.addColumn(sessionExercises, sessionExercises.supersetGroup);
          }
          if (from < 9) {
            await m.addColumn(userSettings, userSettings.themeMode);
          }
          if (from < 10) {
            await m.addColumn(userSettings, userSettings.healthConnectEnabled);
          }
        },
        beforeOpen: (details) async {
          // Required for onDelete: KeyAction.cascade to actually take effect —
          // SQLite ignores foreign key constraints unless this is set per connection.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'gymapp',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
