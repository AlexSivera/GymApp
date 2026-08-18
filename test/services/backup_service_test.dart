import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/data/database/app_database.dart';
import 'package:gymapp/services/backup/backup_service.dart';

void main() {
  late AppDatabase source;
  late AppDatabase target;

  setUp(() {
    source = AppDatabase.forTesting(NativeDatabase.memory());
    target = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async {
    await source.close();
    await target.close();
  });

  test('export then import round-trips routines, a session and a superset group', () async {
    await source.userSettingsDao.updateSettings(const UserSettingsCompanion(
      name: Value('Alex'),
      themeMode: Value('pastel_green'),
    ));

    final benchId =
        await source.exercisesDao.insert(ExercisesCompanion.insert(name: 'Press banca'));
    final customId = await source.exercisesDao
        .insert(ExercisesCompanion.insert(name: 'Mi ejercicio', isCustom: const Value(true)));

    final routineId =
        await source.routinesDao.createRoutine(RoutinesCompanion.insert(name: 'Empuje'));
    final dayId = await source.routinesDao
        .createDay(RoutineDaysCompanion.insert(routineId: routineId, name: 'Día 1', dayOrder: 0));
    final reA = await source.routinesDao.addExerciseToDay(RoutineExercisesCompanion.insert(
      routineDayId: dayId,
      exerciseId: benchId,
      orderIndex: 0,
      targetSets: 3,
      targetRepsMin: 8,
      targetRepsMax: 12,
    ));
    await source.routinesDao.updateRoutineExercise(
      (await (source.select(source.routineExercises)..where((r) => r.id.equals(reA))).getSingle())
          .copyWith(supersetGroup: Value(reA)),
    );
    await source.routinesDao.addExerciseToDay(RoutineExercisesCompanion.insert(
      routineDayId: dayId,
      exerciseId: customId,
      orderIndex: 1,
      targetSets: 3,
      targetRepsMin: 8,
      targetRepsMax: 12,
      supersetGroup: Value(reA),
    ));

    final sessionId = await source.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
      date: DateTime(2026, 8, 18),
      routineDayId: Value(dayId),
      status: const Value(SessionStatus.completed),
    ));
    final sessionExerciseId =
        await source.sessionLoggingDao.addSessionExercise(SessionExercisesCompanion.insert(
      workoutSessionId: sessionId,
      exerciseId: benchId,
      orderIndex: 0,
    ));
    await source.sessionLoggingDao.addSet(WorkoutSetsCompanion.insert(
      sessionExerciseId: sessionExerciseId,
      setNumber: 1,
      weightKg: const Value(80),
      reps: const Value(8),
      isCompleted: const Value(true),
    ));

    await source.personalRecordsDao.insert(PersonalRecordsCompanion.insert(
      exerciseId: benchId,
      type: PersonalRecordType.maxWeight,
      value: 80,
      achievedAt: DateTime(2026, 8, 18),
    ));
    await source.rankingDao.acknowledge(benchId, 2, 1);
    await source.bodyWeightDao
        .insertLog(BodyWeightLogsCompanion.insert(date: DateTime(2026, 8, 18), weightKg: 78.5));

    final json = await exportBackup(source);
    final summary = await importBackup(target, json);

    expect(summary.routines, 1);
    expect(summary.workoutSessions, 1);
    expect(summary.bodyWeightLogs, 1);

    final settings = await target.userSettingsDao.watchSettings().first;
    expect(settings?.name, 'Alex');
    expect(settings?.themeMode, 'pastel_green');

    final exercises = await target.select(target.exercises).get();
    expect(exercises.map((e) => e.name), containsAll(['Press banca', 'Mi ejercicio']));

    final days = await target.routinesDao.watchDays((await target.select(target.routines).get()).single.id).first;
    final importedDay = days.single;
    expect(importedDay.name, 'Día 1');

    final importedExercises = await target.routinesDao.watchExercisesForDay(importedDay.id).first;
    expect(importedExercises, hasLength(2));
    expect(importedExercises[0].supersetGroup != null, true);
    expect(importedExercises[0].supersetGroup, importedExercises[1].supersetGroup);

    final sessions = await target.select(target.workoutSessions).get();
    expect(sessions, hasLength(1));
    expect(sessions.single.routineDayId, importedDay.id);

    final sessionExercises = await target.select(target.sessionExercises).get();
    expect(sessionExercises, hasLength(1));
    final sets = await target.sessionLoggingDao.getSets(sessionExercises.single.id);
    expect(sets, hasLength(1));
    expect(sets.single.weightKg, 80);

    final prs = await target.select(target.personalRecords).get();
    expect(prs, hasLength(1));
    expect(prs.single.value, 80);

    final acknowledgements = await target.rankingDao.watchAcknowledged().first;
    expect(acknowledgements, hasLength(1));
    expect(acknowledgements.single.tierIndex, 2);

    final weightLogs = await target.select(target.bodyWeightLogs).get();
    expect(weightLogs, hasLength(1));
  });

  test('importing an unrelated JSON file throws BackupFormatException', () async {
    expect(
      () => importBackup(target, '{"foo": "bar"}'),
      throwsA(isA<BackupFormatException>()),
    );
  });
}
