// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_logging_dao.dart';

// ignore_for_file: type=lint
mixin _$SessionLoggingDaoMixin on DatabaseAccessor<AppDatabase> {
  $SessionExercisesTable get sessionExercises =>
      attachedDatabase.sessionExercises;
  $WorkoutSetsTable get workoutSets => attachedDatabase.workoutSets;
  SessionLoggingDaoManager get managers => SessionLoggingDaoManager(this);
}

class SessionLoggingDaoManager {
  final _$SessionLoggingDaoMixin _db;
  SessionLoggingDaoManager(this._db);
  $$SessionExercisesTableTableManager get sessionExercises =>
      $$SessionExercisesTableTableManager(
        _db.attachedDatabase,
        _db.sessionExercises,
      );
  $$WorkoutSetsTableTableManager get workoutSets =>
      $$WorkoutSetsTableTableManager(_db.attachedDatabase, _db.workoutSets);
}
