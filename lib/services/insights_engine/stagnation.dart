import '../../data/database/app_database.dart';

class StagnantExercise {
  const StagnantExercise({required this.exerciseId, required this.exerciseName});

  final int exerciseId;
  final String exerciseName;
}

// Flags exercises whose estimated 1RM hasn't improved in the last
// [lookback] training days for that exercise — a simple plateau signal.
Future<List<StagnantExercise>> detectStagnantExercises(
  AppDatabase db, {
  required List<Exercise> allExercises,
  int lookback = 3,
}) async {
  final exercisesById = {for (final e in allExercises) e.id: e};
  final ids = await db.progressDao.exerciseIdsWithHistory();
  final stagnant = <StagnantExercise>[];

  for (final id in ids) {
    final history = await db.progressDao.estimatedOneRepMaxHistory(id);
    if (history.length < lookback + 1) continue;

    final recent = history.last.value;
    final earlier = history[history.length - 1 - lookback].value;
    if (recent <= earlier) {
      final exercise = exercisesById[id];
      if (exercise != null) {
        stagnant.add(StagnantExercise(exerciseId: id, exerciseName: exercise.name));
      }
    }
  }
  return stagnant;
}
