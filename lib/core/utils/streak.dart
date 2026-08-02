// Counts the current workout streak from completed session dates.
//
// `sessionDates` must be sorted most-recent-first and may contain
// duplicates (e.g. two sessions the same day) or times — only the
// calendar day is considered. The streak breaks once the gap between
// two consecutive training days exceeds [maxGapDays], so a normal
// weekly training schedule doesn't reset it every rest day.
int calculateWorkoutStreak(
  List<DateTime> sessionDates, {
  DateTime? now,
  int maxGapDays = 7,
}) {
  if (sessionDates.isEmpty) return 0;

  final today = _dateOnly(now ?? DateTime.now());
  final distinctDays = sessionDates.map(_dateOnly).toSet().toList()
    ..sort((a, b) => b.compareTo(a));

  final mostRecent = distinctDays.first;
  if (today.difference(mostRecent).inDays > maxGapDays) return 0;

  var streak = 1;
  for (var i = 1; i < distinctDays.length; i++) {
    final gap = distinctDays[i - 1].difference(distinctDays[i]).inDays;
    if (gap > maxGapDays) break;
    streak++;
  }
  return streak;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
