import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/data/database/app_database.dart';
import 'package:gymapp/services/calories_engine/estimate_calories_burned.dart';

const _profile = UserProfile(weightKg: 80, age: 30, gender: 'Hombre');

Exercise _strengthExercise({int id = 1}) => Exercise(
      id: id,
      name: 'Press banca',
      primaryMuscles: const ['Pecho'],
      secondaryMuscles: const [],
      category: ExerciseCategory.strength,
      imagePaths: const [],
      isCustom: false,
      createdAt: DateTime(2026, 1, 1),
    );

Exercise _cardioExercise({int id = 2, String name = 'Correr en cinta'}) => Exercise(
      id: id,
      name: name,
      primaryMuscles: const ['Cuádriceps'],
      secondaryMuscles: const [],
      category: ExerciseCategory.cardio,
      imagePaths: const [],
      isCustom: false,
      createdAt: DateTime(2026, 1, 1),
    );

WorkoutSet _set({
  int id = 1,
  double? weightKg,
  int? reps,
  int? durationSeconds,
  double? distanceMeters,
  bool isCompleted = true,
}) =>
    WorkoutSet(
      id: id,
      sessionExerciseId: 1,
      setNumber: 1,
      weightKg: weightKg,
      reps: reps,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      isWarmup: false,
      isCompleted: isCompleted,
    );

void main() {
  group('estimateSetCalories', () {
    test('an incomplete set never counts', () {
      final kcal = estimateSetCalories(
        exercise: _strengthExercise(),
        set: _set(weightKg: 80, reps: 10, isCompleted: false),
        profile: _profile,
      );
      expect(kcal, 0);
    });

    test('a strength set with a heavier relative load burns more than a lighter one', () {
      final light = estimateSetCalories(
        exercise: _strengthExercise(),
        set: _set(weightKg: 20, reps: 10),
        profile: _profile,
      );
      final heavy = estimateSetCalories(
        exercise: _strengthExercise(),
        set: _set(weightKg: 100, reps: 10),
        profile: _profile,
      );
      expect(heavy, greaterThan(light));
      expect(light, greaterThan(0));
    });

    test('a strength set with more reps burns more than fewer reps at the same weight', () {
      final fewReps = estimateSetCalories(
        exercise: _strengthExercise(),
        set: _set(weightKg: 60, reps: 5),
        profile: _profile,
      );
      final manyReps = estimateSetCalories(
        exercise: _strengthExercise(),
        set: _set(weightKg: 60, reps: 15),
        profile: _profile,
      );
      expect(manyReps, greaterThan(fewReps));
    });

    test('a bodyweight-only strength set (no weightKg) burns as much as one loaded at bodyweight', () {
      final noWeight = estimateSetCalories(
        exercise: _strengthExercise(),
        set: _set(reps: 12),
        profile: _profile,
      );
      final loadedAtBodyweight = estimateSetCalories(
        exercise: _strengthExercise(),
        set: _set(weightKg: _profile.weightKg, reps: 12),
        profile: _profile,
      );
      expect(noWeight, greaterThan(0));
      expect(noWeight, closeTo(loadedAtBodyweight, 0.01));
    });

    test('a set logged with weightKg 0 (e.g. Crunch, never touched the kg stepper) is not treated as zero effort', () {
      final zeroWeight = estimateSetCalories(
        exercise: _strengthExercise(),
        set: _set(weightKg: 0, reps: 12),
        profile: _profile,
      );
      final noWeight = estimateSetCalories(
        exercise: _strengthExercise(),
        set: _set(reps: 12),
        profile: _profile,
      );
      expect(zeroWeight, closeTo(noWeight, 0.01));
    });

    test('a cardio set uses the logged duration directly', () {
      // 9.0 MET (Correr en cinta) * 80kg * 0.5h = 360, times gender/age
      // correction factors (both 1.0 for this profile) = 360.
      final kcal = estimateSetCalories(
        exercise: _cardioExercise(),
        set: _set(durationSeconds: 30 * 60),
        profile: _profile,
      );
      expect(kcal, closeTo(360, 1));
    });

    test('a cardio set with only distance falls back to a pace estimate instead of zero', () {
      final kcal = estimateSetCalories(
        exercise: _cardioExercise(),
        set: _set(distanceMeters: 5000),
        profile: _profile,
      );
      expect(kcal, greaterThan(0));
    });

    test('a cardio set with neither duration nor distance contributes nothing', () {
      final kcal = estimateSetCalories(
        exercise: _cardioExercise(),
        set: _set(),
        profile: _profile,
      );
      expect(kcal, 0);
    });

    test('women burn slightly less than men for the same set, all else equal', () {
      const menProfile = UserProfile(weightKg: 80, age: 30, gender: 'Hombre');
      const womenProfile = UserProfile(weightKg: 80, age: 30, gender: 'Mujer');
      final forMen = estimateSetCalories(
        exercise: _cardioExercise(),
        set: _set(durationSeconds: 600),
        profile: menProfile,
      );
      final forWomen = estimateSetCalories(
        exercise: _cardioExercise(),
        set: _set(durationSeconds: 600),
        profile: womenProfile,
      );
      expect(forWomen, lessThan(forMen));
    });
  });

  group('ageFromBirthDate', () {
    test('returns null when no birth date is known', () {
      expect(ageFromBirthDate(null), null);
    });

    test('counts a full year once the birthday has passed this year', () {
      final age = ageFromBirthDate(DateTime(1996, 1, 1), now: DateTime(2026, 8, 10));
      expect(age, 30);
    });

    test('does not count this year until the birthday actually happens', () {
      final age = ageFromBirthDate(DateTime(1996, 12, 31), now: DateTime(2026, 8, 10));
      expect(age, 29);
    });
  });

  group('estimateSessionCalories', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('sums calories across every exercise and set in the session', () async {
      final strengthId = await db.exercisesDao.insert(ExercisesCompanion.insert(
        name: 'Press banca',
        primaryMuscles: const Value(['Pecho']),
        isCustom: const Value(true),
      ));
      final cardioId = await db.exercisesDao.insert(ExercisesCompanion.insert(
        name: 'Correr en cinta',
        primaryMuscles: const Value(['Cuádriceps']),
        category: const Value(ExerciseCategory.cardio),
        isCustom: const Value(true),
      ));
      final sessionId = await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
        date: DateTime(2026, 8, 10),
        status: const Value(SessionStatus.completed),
      ));

      final benchSessionExerciseId = await db.sessionLoggingDao.addSessionExercise(
        SessionExercisesCompanion.insert(workoutSessionId: sessionId, exerciseId: strengthId, orderIndex: 0),
      );
      await db.sessionLoggingDao.addSet(WorkoutSetsCompanion.insert(
        sessionExerciseId: benchSessionExerciseId,
        setNumber: 1,
        weightKg: const Value(80),
        reps: const Value(10),
        isCompleted: const Value(true),
      ));

      final runSessionExerciseId = await db.sessionLoggingDao.addSessionExercise(
        SessionExercisesCompanion.insert(workoutSessionId: sessionId, exerciseId: cardioId, orderIndex: 1),
      );
      await db.sessionLoggingDao.addSet(WorkoutSetsCompanion.insert(
        sessionExerciseId: runSessionExerciseId,
        setNumber: 1,
        durationSeconds: const Value(600),
        isCompleted: const Value(true),
      ));

      final total = await estimateSessionCalories(db, sessionId: sessionId, profile: _profile);

      final benchOnly = estimateSetCalories(
        exercise: _strengthExercise(),
        set: _set(weightKg: 80, reps: 10),
        profile: _profile,
      );
      final runOnly = estimateSetCalories(
        exercise: _cardioExercise(),
        set: _set(durationSeconds: 600),
        profile: _profile,
      );
      expect(total, closeTo(benchOnly + runOnly, 0.01));
    });

    test('a session with no exercises burns nothing', () async {
      final sessionId = await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
        date: DateTime(2026, 8, 10),
        status: const Value(SessionStatus.completed),
      ));
      final total = await estimateSessionCalories(db, sessionId: sessionId, profile: _profile);
      expect(total, 0);
    });
  });
}
