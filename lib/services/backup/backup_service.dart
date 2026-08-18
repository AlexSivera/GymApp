import 'dart:convert';

import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';

// "Copia de seguridad" (Perfil > Exportar datos): a portable JSON snapshot
// of everything the user actually created — ajustes, rutinas, historial de
// entrenamientos, récords, peso corporal. Deliberately excludes the bundled
// exercise catalog (~130 rows, see exercise_seeder.dart) since that gets
// recreated deterministically from the app itself on every launch;
// including it would just bloat the file. Works identically on every
// platform (including web) since it only touches the database, never the
// filesystem directly — the caller handles turning the JSON string into an
// actual file via file_picker.
//
// Exercises referenced by a routine/session/record/rank-acknowledgement are
// matched on import by exact name against what's already on the device
// (covers the bundled catalog) and only inserted as new rows when there's
// no match (custom exercises) — their ids aren't stable across devices, so
// blindly reusing an exported id could silently attach a restored set to
// the wrong exercise.
const _schemaVersionKey = 'schemaVersion';

Future<String> exportBackup(AppDatabase db) async {
  final settings = await (db.select(db.userSettings)..limit(1)).getSingleOrNull();
  final routines = await db.select(db.routines).get();
  final routineDays = await db.select(db.routineDays).get();
  final routineExercises = await db.select(db.routineExercises).get();
  final workoutSessions = await db.select(db.workoutSessions).get();
  final sessionExercises = await db.select(db.sessionExercises).get();
  final workoutSets = await db.select(db.workoutSets).get();
  final personalRecords = await db.select(db.personalRecords).get();
  final rankAcknowledgements = await db.select(db.exerciseRankAcknowledgements).get();
  final bodyWeightLogs = await db.select(db.bodyWeightLogs).get();

  final referencedExerciseIds = <int>{
    for (final re in routineExercises) re.exerciseId,
    for (final se in sessionExercises) se.exerciseId,
    for (final pr in personalRecords) pr.exerciseId,
    for (final ack in rankAcknowledgements) ack.exerciseId,
  };
  final allExercises = await db.select(db.exercises).get();
  final exercises = [
    for (final exercise in allExercises)
      if (exercise.isCustom || referencedExerciseIds.contains(exercise.id)) exercise,
  ];

  final json = {
    _schemaVersionKey: db.schemaVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'userSettings': settings?.toJson(),
    'exercises': [for (final e in exercises) e.toJson()],
    'routines': [for (final r in routines) r.toJson()],
    'routineDays': [for (final d in routineDays) d.toJson()],
    'routineExercises': [for (final re in routineExercises) re.toJson()],
    'workoutSessions': [for (final s in workoutSessions) s.toJson()],
    'sessionExercises': [for (final se in sessionExercises) se.toJson()],
    'workoutSets': [for (final s in workoutSets) s.toJson()],
    'personalRecords': [for (final p in personalRecords) p.toJson()],
    'exerciseRankAcknowledgements': [for (final a in rankAcknowledgements) a.toJson()],
    'bodyWeightLogs': [for (final b in bodyWeightLogs) b.toJson()],
  };
  return const JsonEncoder.withIndent('  ').convert(json);
}

class BackupSummary {
  const BackupSummary({
    required this.routines,
    required this.workoutSessions,
    required this.bodyWeightLogs,
  });

  final int routines;
  final int workoutSessions;
  final int bodyWeightLogs;
}

class BackupFormatException implements Exception {
  BackupFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}

Future<BackupSummary> importBackup(AppDatabase db, String jsonString) async {
  final Map<String, dynamic> data;
  try {
    data = jsonDecode(jsonString) as Map<String, dynamic>;
  } on FormatException {
    throw BackupFormatException('El archivo no es una copia de seguridad válida.');
  }
  if (data[_schemaVersionKey] is! int || data['routines'] is! List) {
    throw BackupFormatException('El archivo no es una copia de seguridad válida.');
  }

  return db.transaction(() async {
    final settingsJson = data['userSettings'] as Map<String, dynamic>?;
    if (settingsJson != null) {
      final settings = UserSetting.fromJson(settingsJson);
      await db.userSettingsDao
          .updateSettings(settings.toCompanion(true).copyWith(id: const Value.absent()));
    }

    final exerciseIdMap = <int, int>{};
    final existingExercisesByName = {
      for (final e in await db.select(db.exercises).get()) e.name: e,
    };
    for (final raw in (data['exercises'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final exercise = Exercise.fromJson(raw);
      final existing = existingExercisesByName[exercise.name];
      if (existing != null) {
        exerciseIdMap[exercise.id] = existing.id;
      } else {
        final newId =
            await db.exercisesDao.insert(exercise.toCompanion(true).copyWith(id: const Value.absent()));
        exerciseIdMap[exercise.id] = newId;
        existingExercisesByName[exercise.name] = exercise.copyWith(id: newId);
      }
    }

    // Routines always come in as new rows — there's no "same routine"
    // concept to dedupe against, unlike exercises.
    final routineIdMap = <int, int>{};
    for (final raw in (data['routines'] as List).cast<Map<String, dynamic>>()) {
      final routine = Routine.fromJson(raw);
      final newId =
          await db.routinesDao.createRoutine(routine.toCompanion(true).copyWith(id: const Value.absent()));
      routineIdMap[routine.id] = newId;
    }

    final routineDayIdMap = <int, int>{};
    for (final raw in (data['routineDays'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final day = RoutineDay.fromJson(raw);
      final routineId = routineIdMap[day.routineId];
      if (routineId == null) continue;
      final newId = await db.routinesDao.createDay(
        day.toCompanion(true).copyWith(id: const Value.absent(), routineId: Value(routineId)),
      );
      routineDayIdMap[day.id] = newId;
    }

    // supersetGroup reuses another RoutineExercise's own id as the group id
    // (see routines_table.dart) — inserted rows can't reference each other's
    // new ids until they all exist, so it's remapped in a second pass below.
    final routineExerciseIdMap = <int, int>{};
    final routineExerciseGroups = <int, int>{};
    for (final raw in (data['routineExercises'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final re = RoutineExercise.fromJson(raw);
      final routineDayId = routineDayIdMap[re.routineDayId];
      final exerciseId = exerciseIdMap[re.exerciseId];
      if (routineDayId == null || exerciseId == null) continue;
      final newId = await db.routinesDao.addExerciseToDay(re.toCompanion(true).copyWith(
            id: const Value.absent(),
            routineDayId: Value(routineDayId),
            exerciseId: Value(exerciseId),
            supersetGroup: const Value.absent(),
          ));
      routineExerciseIdMap[re.id] = newId;
      if (re.supersetGroup != null) routineExerciseGroups[newId] = re.supersetGroup!;
    }
    for (final entry in routineExerciseGroups.entries) {
      final newGroupId = routineExerciseIdMap[entry.value];
      if (newGroupId == null) continue;
      final row = await (db.select(db.routineExercises)..where((r) => r.id.equals(entry.key))).getSingle();
      await db.routinesDao.updateRoutineExercise(row.copyWith(supersetGroup: Value(newGroupId)));
    }

    final workoutSessionIdMap = <int, int>{};
    for (final raw in (data['workoutSessions'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final session = WorkoutSession.fromJson(raw);
      final routineDayId =
          session.routineDayId == null ? null : routineDayIdMap[session.routineDayId];
      final newId = await db.workoutSessionsDao.createSession(session.toCompanion(true).copyWith(
            id: const Value.absent(),
            routineDayId: Value(routineDayId),
          ));
      workoutSessionIdMap[session.id] = newId;
    }

    final sessionExerciseIdMap = <int, int>{};
    final sessionExerciseGroups = <int, int>{};
    for (final raw in (data['sessionExercises'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final se = SessionExercise.fromJson(raw);
      final workoutSessionId = workoutSessionIdMap[se.workoutSessionId];
      final exerciseId = exerciseIdMap[se.exerciseId];
      if (workoutSessionId == null || exerciseId == null) continue;
      final newId = await db.sessionLoggingDao.addSessionExercise(se.toCompanion(true).copyWith(
            id: const Value.absent(),
            workoutSessionId: Value(workoutSessionId),
            exerciseId: Value(exerciseId),
            supersetGroup: const Value.absent(),
          ));
      sessionExerciseIdMap[se.id] = newId;
      if (se.supersetGroup != null) sessionExerciseGroups[newId] = se.supersetGroup!;
    }
    for (final entry in sessionExerciseGroups.entries) {
      final newGroupId = sessionExerciseIdMap[entry.value];
      if (newGroupId == null) continue;
      final row =
          await (db.select(db.sessionExercises)..where((s) => s.id.equals(entry.key))).getSingle();
      await db.sessionLoggingDao.updateSessionExercise(row.copyWith(supersetGroup: Value(newGroupId)));
    }

    for (final raw in (data['workoutSets'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final set = WorkoutSet.fromJson(raw);
      final sessionExerciseId = sessionExerciseIdMap[set.sessionExerciseId];
      if (sessionExerciseId == null) continue;
      await db.sessionLoggingDao.addSet(set.toCompanion(true).copyWith(
            id: const Value.absent(),
            sessionExerciseId: Value(sessionExerciseId),
          ));
    }

    for (final raw in (data['personalRecords'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final pr = PersonalRecord.fromJson(raw);
      final exerciseId = exerciseIdMap[pr.exerciseId];
      if (exerciseId == null) continue;
      // setId isn't remapped — re-linking to the exact restored set isn't
      // worth the extra bookkeeping; the record's own value/reps/date is
      // what matters and survives regardless.
      await db.personalRecordsDao.insert(pr.toCompanion(true).copyWith(
            id: const Value.absent(),
            exerciseId: Value(exerciseId),
            setId: const Value.absent(),
          ));
    }

    for (final raw
        in (data['exerciseRankAcknowledgements'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final ack = ExerciseRankAcknowledgement.fromJson(raw);
      final exerciseId = exerciseIdMap[ack.exerciseId];
      if (exerciseId == null) continue;
      await db.rankingDao.acknowledge(exerciseId, ack.tierIndex, ack.subTier);
    }

    for (final raw in (data['bodyWeightLogs'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final log = BodyWeightLog.fromJson(raw);
      await db.bodyWeightDao.insertLog(log.toCompanion(true).copyWith(id: const Value.absent()));
    }

    return BackupSummary(
      routines: routineIdMap.length,
      workoutSessions: workoutSessionIdMap.length,
      bodyWeightLogs: (data['bodyWeightLogs'] as List? ?? const []).length,
    );
  });
}
