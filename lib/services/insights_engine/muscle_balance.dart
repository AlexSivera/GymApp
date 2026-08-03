import '../../data/database/app_database.dart';

class MuscleVolume {
  const MuscleVolume({required this.muscle, required this.volume});

  final String muscle;
  final double volume;
}

// Rolls up per-exercise volume into per-muscle-group totals over the last
// [days]. A set counts toward every primary muscle listed for its exercise.
Future<List<MuscleVolume>> computeMuscleBalance(
  AppDatabase db, {
  required List<Exercise> allExercises,
  int days = 30,
}) async {
  final end = DateTime.now();
  final start = end.subtract(Duration(days: days));
  final volumeByExercise = await db.progressDao.volumeByExerciseInRange(start, end);
  final exercisesById = {for (final e in allExercises) e.id: e};

  final volumeByMuscle = <String, double>{};
  volumeByExercise.forEach((exerciseId, volume) {
    final exercise = exercisesById[exerciseId];
    if (exercise == null) return;
    for (final muscle in exercise.primaryMuscles) {
      volumeByMuscle[muscle] = (volumeByMuscle[muscle] ?? 0) + volume;
    }
  });

  final result = volumeByMuscle.entries
      .map((e) => MuscleVolume(muscle: e.key, volume: e.value))
      .toList()
    ..sort((a, b) => b.volume.compareTo(a.volume));
  return result;
}
