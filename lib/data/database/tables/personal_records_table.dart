import 'package:drift/drift.dart';

import '../enums.dart';
import 'exercises_table.dart';
import 'workout_sessions_table.dart';

class PersonalRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get type => intEnum<PersonalRecordType>()();
  RealColumn get value => real()();
  IntColumn get reps => integer().nullable()();
  DateTimeColumn get achievedAt => dateTime()();
  IntColumn get setId => integer().nullable().references(WorkoutSets, #id)();
}
