import 'package:drift/drift.dart';

import 'exercises_table.dart';

// One row per exercise the user has stepped through in the "Clasificar
// ejercicios" reveal flow. Until an exercise has a row here it doesn't
// count toward its muscle's rank or show up in the Rangos screen, even if
// it already has enough workout history to compute a rank — the reveal
// flow is the deliberate, one-time "unlock" moment.
class ExerciseRankAcknowledgements extends Table {
  IntColumn get exerciseId => integer().references(Exercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get tierIndex => integer()();
  IntColumn get subTier => integer()();
  DateTimeColumn get acknowledgedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {exerciseId};
}
