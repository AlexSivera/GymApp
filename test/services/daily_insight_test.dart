import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/data/database/app_database.dart';
import 'package:gymapp/services/insights_engine/daily_insight.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('falls back to a generic message when there is no training history', () async {
    final insight = await computeDailyInsight(db, now: DateTime(2026, 8, 3));
    expect(insight.message, isNotEmpty);
  });

  test('picking the same day twice returns the same insight (deterministic)', () async {
    final exerciseId = await db.exercisesDao.createCustomExercise(ExercisesCompanion.insert(
      name: 'Press banca',
      primaryMuscles: const Value(['pecho']),
      isCustom: const Value(true),
    ));
    final sessionId = await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
      date: DateTime(2026, 7, 20),
      status: const Value(SessionStatus.completed),
    ));
    final sessionExerciseId = await db.sessionLoggingDao.addSessionExercise(
      SessionExercisesCompanion.insert(workoutSessionId: sessionId, exerciseId: exerciseId, orderIndex: 0),
    );
    await db.sessionLoggingDao.addSet(WorkoutSetsCompanion.insert(
      sessionExerciseId: sessionExerciseId,
      setNumber: 1,
      weightKg: const Value(80),
      reps: const Value(10),
      isCompleted: const Value(true),
    ));

    final first = await computeDailyInsight(db, now: DateTime(2026, 8, 3));
    final second = await computeDailyInsight(db, now: DateTime(2026, 8, 3));
    expect(first.message, second.message);
  });
}
