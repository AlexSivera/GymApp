import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'converters.dart';
import 'daos/body_weight_dao.dart';
import 'daos/exercises_dao.dart';
import 'daos/routines_dao.dart';
import 'daos/session_logging_dao.dart';
import 'daos/workout_sessions_dao.dart';
import 'enums.dart';
import 'tables/body_weight_logs_table.dart';
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
], daos: [
  WorkoutSessionsDao,
  BodyWeightDao,
  ExercisesDao,
  RoutinesDao,
  SessionLoggingDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // Required for onDelete: KeyAction.cascade to actually take effect —
          // SQLite ignores foreign key constraints unless this is set per connection.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gymapp.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
