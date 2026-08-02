// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_sessions_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkoutSessionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $RoutinesTable get routines => attachedDatabase.routines;
  $RoutineDaysTable get routineDays => attachedDatabase.routineDays;
  $WorkoutSessionsTable get workoutSessions => attachedDatabase.workoutSessions;
  WorkoutSessionsDaoManager get managers => WorkoutSessionsDaoManager(this);
}

class WorkoutSessionsDaoManager {
  final _$WorkoutSessionsDaoMixin _db;
  WorkoutSessionsDaoManager(this._db);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db.attachedDatabase, _db.routines);
  $$RoutineDaysTableTableManager get routineDays =>
      $$RoutineDaysTableTableManager(_db.attachedDatabase, _db.routineDays);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(
        _db.attachedDatabase,
        _db.workoutSessions,
      );
}
