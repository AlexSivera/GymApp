// Las esferas del dragón: one esfera per calendar week (Monday–Sunday) in
// which the weekly target of completed sessions was met. Seven summon
// Shenlong; once a wish is granted the esferas scatter and counting starts
// again from the week after the wish.
const dragonBallsToSummon = 7;

class DragonBallProgress {
  const DragonBallProgress({
    required this.count,
    required this.thisWeekCompleted,
    required this.weeklyTarget,
    required this.thisWeekMet,
  });

  // 0..7 — esferas currently held.
  final int count;
  final int thisWeekCompleted;
  final int weeklyTarget;
  // This week already earned (or will count as) an esfera.
  final bool thisWeekMet;

  bool get canSummon => count >= dragonBallsToSummon;
  int get remainingThisWeek => thisWeekMet ? 0 : (weeklyTarget - thisWeekCompleted).clamp(0, weeklyTarget);
}

DateTime weekStartOf(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

// [completedDates]: dates of every completed session (any order).
// [countFrom]: when the last wish was granted — only weeks after that one
// count. Null counts the whole history.
// [protectedWeeks]: week starts granted by the "semana libre" wish, which
// count as met no matter how many sessions they had.
DragonBallProgress computeDragonBalls({
  required List<DateTime> completedDates,
  required int weeklyTarget,
  DateTime? countFrom,
  Set<DateTime> protectedWeeks = const {},
  DateTime? now,
}) {
  final target = weeklyTarget < 1 ? 1 : weeklyTarget;
  final currentWeek = weekStartOf(now ?? DateTime.now());

  final perWeek = <DateTime, int>{};
  for (final date in completedDates) {
    final week = weekStartOf(date);
    perWeek[week] = (perWeek[week] ?? 0) + 1;
  }
  final protected = {for (final week in protectedWeeks) weekStartOf(week)};

  final thisWeekCompleted = perWeek[currentWeek] ?? 0;
  final thisWeekMet = thisWeekCompleted >= target || protected.contains(currentWeek);

  // Weeks strictly after the wish's week.
  final firstCountedWeek = countFrom == null ? null : weekStartOf(countFrom).add(const Duration(days: 7));
  bool counts(DateTime week) => firstCountedWeek == null || !week.isBefore(firstCountedWeek);

  final metWeeks = <DateTime>{
    for (final entry in perWeek.entries)
      if (entry.value >= target && counts(entry.key) && !entry.key.isAfter(currentWeek)) entry.key,
    for (final week in protected)
      if (counts(week) && !week.isAfter(currentWeek)) week,
  };

  return DragonBallProgress(
    count: metWeeks.length.clamp(0, dragonBallsToSummon),
    thisWeekCompleted: thisWeekCompleted,
    weeklyTarget: target,
    thisWeekMet: thisWeekMet,
  );
}
