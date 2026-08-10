import 'package:drift/drift.dart';

import '../converters.dart';
import '../enums.dart';

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get primaryMuscles =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  TextColumn get secondaryMuscles =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  TextColumn get equipment => text().nullable()();
  // Determines which fields the workout-session set editor shows: kg/reps
  // for strength, minutes/km for cardio.
  IntColumn get category =>
      intEnum<ExerciseCategory>().withDefault(Constant(ExerciseCategory.strength.index))();
  TextColumn get imagePaths =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  TextColumn get videoUrl => text().nullable()();
  TextColumn get instructions => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get externalId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
