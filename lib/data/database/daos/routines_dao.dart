import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/routines_table.dart';

part 'routines_dao.g.dart';

@DriftAccessor(tables: [Routines, RoutineDays, RoutineExercises])
class RoutinesDao extends DatabaseAccessor<AppDatabase> with _$RoutinesDaoMixin {
  RoutinesDao(super.db);

  Stream<List<Routine>> watchAllRoutines() {
    return (select(routines)
          ..where((r) => r.isArchived.equals(false))
          ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
        .watch();
  }

  Stream<List<Routine>> watchArchivedRoutines() {
    return (select(routines)
          ..where((r) => r.isArchived.equals(true))
          ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
        .watch();
  }

  Stream<Routine?> watchRoutine(int id) {
    return (select(routines)..where((r) => r.id.equals(id))).watchSingleOrNull();
  }

  Future<int> createRoutine(RoutinesCompanion entry) => into(routines).insert(entry);

  Future<bool> updateRoutine(Routine routine) => update(routines).replace(routine);

  Future<void> setArchived(int id, bool archived) => (update(routines)..where((r) => r.id.equals(id)))
      .write(RoutinesCompanion(isArchived: Value(archived), updatedAt: Value(DateTime.now())));

  Future<int> deleteRoutine(int id) =>
      (delete(routines)..where((r) => r.id.equals(id))).go();

  Stream<List<RoutineDay>> watchDays(int routineId) {
    return (select(routineDays)
          ..where((d) => d.routineId.equals(routineId))
          ..orderBy([(d) => OrderingTerm.asc(d.dayOrder)]))
        .watch();
  }

  // Total exercises across every day of the routine — used by the routine
  // list cards ("N ejercicios"). A live stream (not a one-off Future) so it
  // stays correct if it's first watched mid-way through building a routine
  // (e.g. right after the Routine row is created but before its exercises
  // are added) instead of caching whatever count happened to be true then.
  Stream<int> watchExerciseCountInRoutine(int routineId) {
    final query = selectOnly(routineExercises)
      ..addColumns([routineExercises.id])
      ..join([innerJoin(routineDays, routineDays.id.equalsExp(routineExercises.routineDayId))])
      ..where(routineDays.routineId.equals(routineId));
    return query.watch().map((rows) => rows.length);
  }

  Stream<RoutineDay?> watchDayById(int id) {
    return (select(routineDays)..where((d) => d.id.equals(id))).watchSingleOrNull();
  }

  Future<int> createDay(RoutineDaysCompanion entry) => into(routineDays).insert(entry);

  Future<bool> updateDay(RoutineDay day) => update(routineDays).replace(day);

  Future<int> deleteDay(int id) =>
      (delete(routineDays)..where((d) => d.id.equals(id))).go();

  Future<void> reorderDays(List<int> dayIdsInOrder) async {
    await batch((b) {
      for (var i = 0; i < dayIdsInOrder.length; i++) {
        b.update(
          routineDays,
          RoutineDaysCompanion(dayOrder: Value(i)),
          where: (d) => d.id.equals(dayIdsInOrder[i]),
        );
      }
    });
  }

  Stream<List<RoutineExercise>> watchExercisesForDay(int routineDayId) {
    return (select(routineExercises)
          ..where((e) => e.routineDayId.equals(routineDayId))
          ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
        .watch();
  }

  Future<int> addExerciseToDay(RoutineExercisesCompanion entry) =>
      into(routineExercises).insert(entry);

  Future<bool> updateRoutineExercise(RoutineExercise entry) =>
      update(routineExercises).replace(entry);

  Future<int> removeExerciseFromDay(int id) =>
      (delete(routineExercises)..where((e) => e.id.equals(id))).go();

  Future<void> reorderExercises(List<int> routineExerciseIdsInOrder) async {
    await batch((b) {
      for (var i = 0; i < routineExerciseIdsInOrder.length; i++) {
        b.update(
          routineExercises,
          RoutineExercisesCompanion(orderIndex: Value(i)),
          where: (e) => e.id.equals(routineExerciseIdsInOrder[i]),
        );
      }
    });
  }
}
