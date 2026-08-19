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

  // Used to diff the bundled seed list against what's already in the DB —
  // exercise name is the only stable identity the original seed rows have
  // (externalId wasn't recorded when they were first inserted).
  Future<Set<String>> allNames() async {
    final rows = await select(exercises).get();
    return rows.map((r) => r.name).toSet();
  }

  Future<void> insertAll(List<ExercisesCompanion> entries) {
    return batch((b) => b.insertAll(exercises, entries));
  }

  Future<int> insert(ExercisesCompanion entry) {
    return into(exercises).insert(entry);
  }

  // Refreshes a bundled (non-custom) exercise's fields in place, matched by
  // name — used to bring seed rows created by an older data source up to
  // date without touching their id (which routines/sessions reference) or
  // any user-created custom exercise of the same name.
  Future<void> updateSeedFields(String name, ExercisesCompanion data) {
    return (update(exercises)..where((e) => e.name.equals(name) & e.isCustom.equals(false))).write(data);
  }
}
