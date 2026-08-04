import 'package:drift/drift.dart';

import 'exercises_table.dart';

class FavoriteExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.cascade).unique()();
}
