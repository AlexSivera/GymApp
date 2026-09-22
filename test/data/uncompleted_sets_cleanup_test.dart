import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/data/database/app_database.dart';
import 'package:gymapp/services/insights_engine/session_summary.dart';
import 'package:gymapp/services/progression_engine/previous_performance.dart';

void main() {
  late AppDatabase db;
  late int exerciseId;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    exerciseId = await db.exercisesDao.insert(ExercisesCompanion.insert(
      name: 'Sentadilla',
      isCustom: const Value(true),
    ));
  });
  tearDown(() => db.close());

  // One session with the given sets for the exercise: each entry is
  // (weightKg, reps, isCompleted) — pre-filled-but-never-ticked sets are
  // exactly what opening an exercise mid-workout leaves behind.
  Future<int> sessionWithSets(
    DateTime date,
    SessionStatus status,
    List<(double, int, bool)> sets,
  ) async {
    final sessionId = await db.workoutSessionsDao.createSession(
      WorkoutSessionsCompanion.insert(date: date, status: Value(status)),
    );
    final sessionExerciseId = await db.sessionLoggingDao.addSessionExercise(
      SessionExercisesCompanion.insert(workoutSessionId: sessionId, exerciseId: exerciseId, orderIndex: 0),
    );
    for (var i = 0; i < sets.length; i++) {
      await db.sessionLoggingDao.addSet(WorkoutSetsCompanion.insert(
        sessionExerciseId: sessionExerciseId,
        setNumber: i + 1,
        weightKg: Value(sets[i].$1),
        reps: Value(sets[i].$2),
        isCompleted: Value(sets[i].$3),
      ));
    }
    return sessionId;
  }

  Future<List<WorkoutSet>> setsOf(int sessionId) async {
    final exercises = await db.sessionLoggingDao.watchSessionExercises(sessionId).first;
    return db.sessionLoggingDao.getSets(exercises.single.id);
  }

  test('finishing a session drops the sets that were never ticked off', () async {
    final sessionId = await sessionWithSets(DateTime(2026, 9, 23), SessionStatus.completed, [
      (10, 12, true),
      (10, 12, false),
      (10, 12, false),
    ]);

    await db.sessionLoggingDao.deleteUncompletedSetsOfFinishedSessions(sessionId: sessionId);

    final remaining = await setsOf(sessionId);
    expect(remaining, hasLength(1));
    expect(remaining.single.isCompleted, isTrue);

    final summary = await computeSessionSummary(db, sessionId: sessionId);
    expect(summary.volumeThisSession, 120, reason: 'only the one real 10 kg × 12 set counts');
  });

  test('the startup cleanup only touches finished sessions, never the one in progress', () async {
    final finished = await sessionWithSets(DateTime(2026, 9, 20), SessionStatus.completed, [
      (10, 12, true),
      (10, 12, false),
    ]);
    final inProgress = await sessionWithSets(DateTime(2026, 9, 23), SessionStatus.inProgress, [
      (10, 12, true),
      (10, 12, false),
    ]);

    await db.sessionLoggingDao.deleteUncompletedSetsOfFinishedSessions();

    expect(await setsOf(finished), hasLength(1));
    expect(await setsOf(inProgress), hasLength(2), reason: 'pending sets of a live workout are still to do');
  });

  test('"última vez" skips a past session where the exercise was listed but never done', () async {
    await sessionWithSets(DateTime(2026, 9, 10), SessionStatus.completed, [(20, 10, true)]);
    await sessionWithSets(DateTime(2026, 9, 15), SessionStatus.completed, [(0, 12, false)]);
    final current = await sessionWithSets(DateTime(2026, 9, 23), SessionStatus.inProgress, []);

    final previous = await getPreviousSetsForExercise(db, exerciseId: exerciseId, excludeSessionId: current);

    expect(previous, hasLength(1));
    expect(previous.single.weightKg, 20);
  });
}
