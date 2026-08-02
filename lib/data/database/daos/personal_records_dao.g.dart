// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_records_dao.dart';

// ignore_for_file: type=lint
mixin _$PersonalRecordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $RoutinesTable get routines => attachedDatabase.routines;
  $RoutineDaysTable get routineDays => attachedDatabase.routineDays;
  $WorkoutSessionsTable get workoutSessions => attachedDatabase.workoutSessions;
  $SessionExercisesTable get sessionExercises =>
      attachedDatabase.sessionExercises;
  $WorkoutSetsTable get workoutSets => attachedDatabase.workoutSets;
  $PersonalRecordsTable get personalRecords => attachedDatabase.personalRecords;
  PersonalRecordsDaoManager get managers => PersonalRecordsDaoManager(this);
}

class PersonalRecordsDaoManager {
  final _$PersonalRecordsDaoMixin _db;
  PersonalRecordsDaoManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db.attachedDatabase, _db.routines);
  $$RoutineDaysTableTableManager get routineDays =>
      $$RoutineDaysTableTableManager(_db.attachedDatabase, _db.routineDays);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(
        _db.attachedDatabase,
        _db.workoutSessions,
      );
  $$SessionExercisesTableTableManager get sessionExercises =>
      $$SessionExercisesTableTableManager(
        _db.attachedDatabase,
        _db.sessionExercises,
      );
  $$WorkoutSetsTableTableManager get workoutSets =>
      $$WorkoutSetsTableTableManager(_db.attachedDatabase, _db.workoutSets);
  $$PersonalRecordsTableTableManager get personalRecords =>
      $$PersonalRecordsTableTableManager(
        _db.attachedDatabase,
        _db.personalRecords,
      );
}
