import '../../data/database/app_database.dart';

class WeeklySummary {
  const WeeklySummary({
    required this.sessionsThisWeek,
    required this.prsThisWeek,
    required this.volumeThisWeek,
    required this.volumeLastWeek,
  });

  final int sessionsThisWeek;
  final int prsThisWeek;
  final double volumeThisWeek;
  final double volumeLastWeek;

  double? get volumeChangePercent {
    if (volumeLastWeek <= 0) return null;
    return (volumeThisWeek - volumeLastWeek) / volumeLastWeek * 100;
  }
}

Future<WeeklySummary> computeWeeklySummary(AppDatabase db, {DateTime? now}) async {
  final today = now ?? DateTime.now();
  final startOfThisWeek = _startOfWeek(today);
  final endOfThisWeek = startOfThisWeek.add(const Duration(days: 7));
  final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));

  final sessionsThisWeek = await db.workoutSessionsDao
      .getCompletedSessionsInRange(startOfThisWeek, endOfThisWeek);
  final prsThisWeek =
      await db.personalRecordsDao.countAchievedInRange(startOfThisWeek, endOfThisWeek);
  final volumeThisWeek =
      await db.progressDao.totalVolumeInRange(startOfThisWeek, endOfThisWeek);
  final volumeLastWeek =
      await db.progressDao.totalVolumeInRange(startOfLastWeek, startOfThisWeek);

  return WeeklySummary(
    sessionsThisWeek: sessionsThisWeek.length,
    prsThisWeek: prsThisWeek,
    volumeThisWeek: volumeThisWeek,
    volumeLastWeek: volumeLastWeek,
  );
}

DateTime _startOfWeek(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
}
