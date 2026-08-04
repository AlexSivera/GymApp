// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_sessions_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkoutSessionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkoutSessionsTable get workoutSessions => attachedDatabase.workoutSessions;
  WorkoutSessionsDaoManager get managers => WorkoutSessionsDaoManager(this);
}

class WorkoutSessionsDaoManager {
  final _$WorkoutSessionsDaoMixin _db;
  WorkoutSessionsDaoManager(this._db);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(
        _db.attachedDatabase,
        _db.workoutSessions,
      );
}
