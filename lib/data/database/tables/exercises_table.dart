import 'package:drift/drift.dart';

import '../converters.dart';

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get primaryMuscles =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  TextColumn get secondaryMuscles =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  TextColumn get equipment => text().nullable()();
  TextColumn get imagePaths =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  TextColumn get videoUrl => text().nullable()();
  TextColumn get instructions => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get externalId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
