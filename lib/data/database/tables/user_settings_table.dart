import 'package:drift/drift.dart';

// Single-row table: the app only ever reads/writes the row with id = 1.
class UserSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get units => text().withDefault(const Constant('kg'))();
  TextColumn get name => text().nullable()();
  TextColumn get goals => text().nullable()();
  IntColumn get weeklyTargetSessions => integer().withDefault(const Constant(4))();
}
