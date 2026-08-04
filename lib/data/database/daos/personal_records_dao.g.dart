// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_records_dao.dart';

// ignore_for_file: type=lint
mixin _$PersonalRecordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PersonalRecordsTable get personalRecords => attachedDatabase.personalRecords;
  $ExercisesTable get exercises => attachedDatabase.exercises;
  PersonalRecordsDaoManager get managers => PersonalRecordsDaoManager(this);
}

class PersonalRecordsDaoManager {
  final _$PersonalRecordsDaoMixin _db;
  PersonalRecordsDaoManager(this._db);
  $$PersonalRecordsTableTableManager get personalRecords =>
      $$PersonalRecordsTableTableManager(
        _db.attachedDatabase,
        _db.personalRecords,
      );
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
}
