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

  Stream<Routine?> watchRoutine(int id) {
    return (select(routines)..where((r) => r.id.equals(id))).watchSingleOrNull();
  }

  Future<int> createRoutine(RoutinesCompanion entry) => into(routines).insert(entry);

  Future<bool> updateRoutine(Routine routine) => update(routines).replace(routine);

  Future<int> deleteRoutine(int id) =>
      (delete(routines)..where((r) => r.id.equals(id))).go();

  Stream<List<RoutineDay>> watchDays(int routineId) {
    return (select(routineDays)
          ..where((d) => d.routineId.equals(routineId))
          ..orderBy([(d) => OrderingTerm.asc(d.dayOrder)]))
        .watch();
  }

  // Total exercises across every day of the routine — used by the routine
  // list cards ("N ejercicios").
  Future<int> countExercisesInRoutine(int routineId) async {
    final query = selectOnly(routineExercises)
      ..addColumns([routineExercises.id])
      ..join([innerJoin(routineDays, routineDays.id.equalsExp(routineExercises.routineDayId))])
      ..where(routineDays.routineId.equals(routineId));
    final rows = await query.get();
    return rows.length;
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
