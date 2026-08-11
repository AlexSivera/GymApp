import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/data/database/app_database.dart';
import 'package:gymapp/services/ranking_engine/compute_new_rank_achievements.dart';
import 'package:gymapp/services/ranking_engine/rank_tier.dart';

void main() {
  group('computeNewRankAchievements — rep-based (bodyweight) exercises', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<int> completedSessionWithSets(String exerciseName, List<int> repsPerSet) async {
      final exerciseId = await db.exercisesDao.insert(ExercisesCompanion.insert(
        name: exerciseName,
        primaryMuscles: const Value(['Abdomen']),
        isCustom: const Value(true),
      ));
      final sessionId = await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
        date: DateTime(2026, 8, 12),
        status: const Value(SessionStatus.completed),
      ));
      final sessionExerciseId = await db.sessionLoggingDao.addSessionExercise(
        SessionExercisesCompanion.insert(workoutSessionId: sessionId, exerciseId: exerciseId, orderIndex: 0),
      );
      for (var i = 0; i < repsPerSet.length; i++) {
        await db.sessionLoggingDao.addSet(WorkoutSetsCompanion.insert(
          sessionExerciseId: sessionExerciseId,
          setNumber: i + 1,
          weightKg: const Value(0),
          reps: Value(repsPerSet[i]),
          isCompleted: const Value(true),
        ));
      }
      return sessionId;
    }

    test('a bodyweight ab exercise (Crunch) gets ranked by reps, not by a 0kg 1RM', () async {
      final sessionId = await completedSessionWithSets('Crunch', [15]);
      final achievements = await computeNewRankAchievements(db, sessionId: sessionId);

      expect(achievements, hasLength(1));
      expect(achievements.first.exercise.name, 'Crunch');
      expect(achievements.first.bestSet.reps, 15);
      // baseline is 20 reps; 15/20 = 0.75, which lands in Bronce (0.62-0.85).
      expect(achievements.first.rank.tier, RankTier.bronce);
    });

    test('the highest-rep set wins as "best", not an arbitrary 0kg-tied set', () async {
      final sessionId = await completedSessionWithSets('Crunch', [10, 25, 18]);
      final achievements = await computeNewRankAchievements(db, sessionId: sessionId);

      expect(achievements, hasLength(1));
      expect(achievements.first.bestSet.reps, 25, reason: 'the 25-rep set beats the 10 and 18-rep ones');
    });

    test('a rep count matching the baseline lands in Plata, same calibration point as weighted lifts', () async {
      final sessionId = await completedSessionWithSets('Crunch', [20]);
      final achievements = await computeNewRankAchievements(db, sessionId: sessionId);

      expect(achievements.first.rank.tier, RankTier.plata);
    });
  });

  group('computeNewRankAchievements — duration-based (isometric) exercises', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<int> completedSessionWithDurationSets(String exerciseName, List<int> secondsPerSet) async {
      final exerciseId = await db.exercisesDao.insert(ExercisesCompanion.insert(
        name: exerciseName,
        primaryMuscles: const Value(['Abdomen']),
        category: const Value(ExerciseCategory.isometric),
        isCustom: const Value(true),
      ));
      final sessionId = await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
        date: DateTime(2026, 8, 12),
        status: const Value(SessionStatus.completed),
      ));
      final sessionExerciseId = await db.sessionLoggingDao.addSessionExercise(
        SessionExercisesCompanion.insert(workoutSessionId: sessionId, exerciseId: exerciseId, orderIndex: 0),
      );
      for (var i = 0; i < secondsPerSet.length; i++) {
        await db.sessionLoggingDao.addSet(WorkoutSetsCompanion.insert(
          sessionExerciseId: sessionExerciseId,
          setNumber: i + 1,
          durationSeconds: Value(secondsPerSet[i]),
          isCompleted: const Value(true),
        ));
      }
      return sessionId;
    }

    test('an isometric hold (Plancha) gets ranked by seconds held', () async {
      final sessionId = await completedSessionWithDurationSets('Plancha', [30]);
      final achievements = await computeNewRankAchievements(db, sessionId: sessionId);

      expect(achievements, hasLength(1));
      expect(achievements.first.exercise.name, 'Plancha');
      expect(achievements.first.bestSet.durationSeconds, 30);
      // baseline is 45s; 30/45 = 0.667, which lands in Bronce (0.62-0.85).
      expect(achievements.first.rank.tier, RankTier.bronce);
    });

    test('the longest hold wins as "best"', () async {
      final sessionId = await completedSessionWithDurationSets('Plancha', [20, 50, 35]);
      final achievements = await computeNewRankAchievements(db, sessionId: sessionId);

      expect(achievements, hasLength(1));
      expect(achievements.first.bestSet.durationSeconds, 50,
          reason: 'the 50s hold beats the 20s and 35s ones');
    });

    test('a hold matching the baseline lands in Plata', () async {
      final sessionId = await completedSessionWithDurationSets('Plancha', [45]);
      final achievements = await computeNewRankAchievements(db, sessionId: sessionId);

      expect(achievements.first.rank.tier, RankTier.plata);
    });
  });
}
