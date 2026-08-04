import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';

// Creates an in-progress WorkoutSession for [date] and pre-populates it
// with one SessionExercise per exercise configured in the routine day
// (same order), ready for the user to start logging sets.
Future<int> startSessionFromRoutineDay(
  AppDatabase db, {
  required int routineDayId,
  required DateTime date,
}) async {
  return db.transaction(() async {
    final sessionId = await db.workoutSessionsDao.createSession(
      WorkoutSessionsCompanion.insert(
        date: date,
        routineDayId: Value(routineDayId),
        status: const Value(SessionStatus.inProgress),
        startedAt: Value(DateTime.now()),
      ),
    );

    final routineExercises = await db.routinesDao.watchExercisesForDay(routineDayId).first;
    for (final entry in routineExercises) {
      await db.sessionLoggingDao.addSessionExercise(SessionExercisesCompanion.insert(
        workoutSessionId: sessionId,
        exerciseId: entry.exerciseId,
        orderIndex: entry.orderIndex,
      ));
    }

    return sessionId;
  });
}

// Promotes an existing `planned` session (created from Home's "Elegir
// rutina" or the calendar) into an in-progress one, pre-populating its
// exercises from the routine day — without creating a second session row
// for the same date.
Future<int> startPlannedSession(AppDatabase db, {required WorkoutSession session}) async {
  return db.transaction(() async {
    await db.workoutSessionsDao.updateSession(session.copyWith(
      status: SessionStatus.inProgress,
      startedAt: Value(DateTime.now()),
    ));

    if (session.routineDayId != null) {
      final routineExercises =
          await db.routinesDao.watchExercisesForDay(session.routineDayId!).first;
      for (final entry in routineExercises) {
        await db.sessionLoggingDao.addSessionExercise(SessionExercisesCompanion.insert(
          workoutSessionId: session.id,
          exerciseId: entry.exerciseId,
          orderIndex: entry.orderIndex,
        ));
      }
    }
    return session.id;
  });
}

// Creates an empty in-progress freestyle session (no routine) for [date].
Future<int> startFreestyleSession(AppDatabase db, {required DateTime date}) {
  return db.workoutSessionsDao.createSession(
    WorkoutSessionsCompanion.insert(
      date: date,
      status: const Value(SessionStatus.inProgress),
      startedAt: Value(DateTime.now()),
    ),
  );
}
