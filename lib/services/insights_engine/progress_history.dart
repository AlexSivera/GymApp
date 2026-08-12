import '../../data/database/app_database.dart';

class WeeklyVolumePoint {
  const WeeklyVolumePoint({required this.weekStart, required this.volume});
  final DateTime weekStart;
  final double volume;
}

class WeeklyFrequencyPoint {
  const WeeklyFrequencyPoint({required this.weekStart, required this.sessions});
  final DateTime weekStart;
  final int sessions;
}

// One line in the muscle-balance trend chart — volumes are in the same
// week order as ProgressHistory.weeks, so index i in every trend lines up
// with weeks[i].
class MuscleVolumeTrend {
  const MuscleVolumeTrend({required this.muscle, required this.weeklyVolumes});
  final String muscle;
  final List<double> weeklyVolumes;
}

class ProgressHistory {
  const ProgressHistory({
    required this.weeks,
    required this.volume,
    required this.frequency,
    required this.muscleTrends,
  });

  final List<DateTime> weeks;
  final List<WeeklyVolumePoint> volume;
  final List<WeeklyFrequencyPoint> frequency;
  final List<MuscleVolumeTrend> muscleTrends;

  bool get hasAnyData => volume.any((v) => v.volume > 0) || frequency.any((f) => f.sessions > 0);
}

DateTime _mondayOf(DateTime d) {
  final date = DateTime(d.year, d.month, d.day);
  return date.subtract(Duration(days: date.weekday - 1));
}

// Builds week-by-week volume, frequency and per-muscle volume trend for the
// last [weekCount] weeks (oldest first, ending with the current week) — the
// data behind the three "gráficas históricas" on the Insights screen. Only
// completed sessions count, same as everywhere else volume is computed.
Future<ProgressHistory> computeProgressHistory(
  AppDatabase db, {
  int weekCount = 8,
  DateTime? now,
}) async {
  final today = now ?? DateTime.now();
  final thisMonday = _mondayOf(today);
  final weeks = [for (var i = weekCount - 1; i >= 0; i--) thisMonday.subtract(Duration(days: 7 * i))];

  final allExercises = await db.exercisesDao.watchAll().first;
  final exercisesById = {for (final e in allExercises) e.id: e};

  final volumePoints = <WeeklyVolumePoint>[];
  final frequencyPoints = <WeeklyFrequencyPoint>[];
  final muscleVolumeByWeek = <Map<String, double>>[];

  for (final weekStart in weeks) {
    final weekEnd = weekStart.add(const Duration(days: 7));

    final byExercise = await db.progressDao.volumeByExerciseInRange(weekStart, weekEnd);
    final totalVolume = byExercise.values.fold<double>(0, (sum, v) => sum + v);
    volumePoints.add(WeeklyVolumePoint(weekStart: weekStart, volume: totalVolume));

    final muscleVolume = <String, double>{};
    byExercise.forEach((exerciseId, volume) {
      final exercise = exercisesById[exerciseId];
      if (exercise == null) return;
      for (final muscle in exercise.primaryMuscles) {
        muscleVolume[muscle] = (muscleVolume[muscle] ?? 0) + volume;
      }
    });
    muscleVolumeByWeek.add(muscleVolume);

    final sessions = await db.workoutSessionsDao.getCompletedSessionsInRange(weekStart, weekEnd);
    frequencyPoints.add(WeeklyFrequencyPoint(weekStart: weekStart, sessions: sessions.length));
  }

  // Top 4 muscles by total volume across the whole window — keeps the trend
  // chart legible instead of drawing a line per muscle group that ever appeared.
  final totalsByMuscle = <String, double>{};
  for (final week in muscleVolumeByWeek) {
    week.forEach((muscle, volume) => totalsByMuscle[muscle] = (totalsByMuscle[muscle] ?? 0) + volume);
  }
  final topMuscles = (totalsByMuscle.keys.toList()
        ..sort((a, b) => totalsByMuscle[b]!.compareTo(totalsByMuscle[a]!)))
      .take(4)
      .toList();

  final muscleTrends = [
    for (final muscle in topMuscles)
      MuscleVolumeTrend(
        muscle: muscle,
        weeklyVolumes: [for (final week in muscleVolumeByWeek) week[muscle] ?? 0],
      ),
  ];

  return ProgressHistory(
    weeks: weeks,
    volume: volumePoints,
    frequency: frequencyPoints,
    muscleTrends: muscleTrends,
  );
}
