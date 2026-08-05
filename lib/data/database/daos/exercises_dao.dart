import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/exercises_table.dart';

part 'exercises_dao.g.dart';

@DriftAccessor(tables: [Exercises])
class ExercisesDao extends DatabaseAccessor<AppDatabase> with _$ExercisesDaoMixin {
  ExercisesDao(super.db);

  Stream<List<Exercise>> watchAll() {
    return (select(exercises)..orderBy([(e) => OrderingTerm.asc(e.name)])).watch();
  }

  Future<int> count() async {
    final rows = await select(exercises).get();
    return rows.length;
  }

  Future<void> insertAll(List<ExercisesCompanion> entries) {
    return batch((b) => b.insertAll(exercises, entries));
  }

  Future<int> insert(ExercisesCompanion entry) {
    return into(exercises).insert(entry);
  }
}
