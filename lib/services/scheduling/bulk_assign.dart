import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';

// Fills [startDate]..[endDate] (inclusive) with planned sessions, cycling
// through the routine's days in order and skipping [restWeekdays]
// (DateTime.weekday values, 1=Monday..7=Sunday) and any date that already
// has a session assigned.
Future<int> bulkAssignRoutine(
  AppDatabase db, {
  required int routineId,
  required DateTime startDate,
  required DateTime endDate,
  Set<int> restWeekdays = const {},
}) async {
  final days = await db.routinesDao.watchDays(routineId).first;
  if (days.isEmpty) return 0;

  final start = DateTime(startDate.year, startDate.month, startDate.day);
  final end = DateTime(endDate.year, endDate.month, endDate.day);
  final existing = await db.workoutSessionsDao
      .watchSessionsInRange(start, end.add(const Duration(days: 1)))
      .first;
  final occupiedDates = existing.map((s) => DateTime(s.date.year, s.date.month, s.date.day)).toSet();

  final entries = <WorkoutSessionsCompanion>[];
  var cursor = start;
  var dayIndex = 0;

  while (!cursor.isAfter(end)) {
    final isRestDay = restWeekdays.contains(cursor.weekday);
    if (!isRestDay && !occupiedDates.contains(cursor)) {
      final routineDay = days[dayIndex % days.length];
      entries.add(WorkoutSessionsCompanion.insert(
        date: cursor,
        routineDayId: Value(routineDay.id),
        status: const Value(SessionStatus.planned),
      ));
      dayIndex++;
    } else if (isRestDay && !occupiedDates.contains(cursor)) {
      entries.add(WorkoutSessionsCompanion.insert(
        date: cursor,
        status: const Value(SessionStatus.rest),
      ));
    }
    cursor = cursor.add(const Duration(days: 1));
  }

  if (entries.isNotEmpty) {
    await db.workoutSessionsDao.createSessions(entries);
  }
  return entries.length;
}

// Assigns a single routine day to an arbitrary (possibly non-contiguous) set
// of dates — used by the calendar's multi-select "Asignar rutina" action.
// Skips dates that already have a session.
Future<int> assignRoutineDayToDates(
  AppDatabase db, {
  required int routineDayId,
  required Set<DateTime> dates,
}) async {
  if (dates.isEmpty) return 0;
  final sorted = dates.map((d) => DateTime(d.year, d.month, d.day)).toList()..sort();
  final existing = await db.workoutSessionsDao
      .watchSessionsInRange(sorted.first, sorted.last.add(const Duration(days: 1)))
      .first;
  final occupied = existing.map((s) => DateTime(s.date.year, s.date.month, s.date.day)).toSet();

  final entries = [
    for (final date in sorted)
      if (!occupied.contains(date))
        WorkoutSessionsCompanion.insert(
          date: date,
          routineDayId: Value(routineDayId),
          status: const Value(SessionStatus.planned),
        ),
  ];
  if (entries.isNotEmpty) {
    await db.workoutSessionsDao.createSessions(entries);
  }
  return entries.length;
}

// Marks an arbitrary set of dates as rest days. Skips dates that already
// have a session.
Future<int> markDatesAsRest(AppDatabase db, {required Set<DateTime> dates}) async {
  if (dates.isEmpty) return 0;
  final sorted = dates.map((d) => DateTime(d.year, d.month, d.day)).toList()..sort();
  final existing = await db.workoutSessionsDao
      .watchSessionsInRange(sorted.first, sorted.last.add(const Duration(days: 1)))
      .first;
  final occupied = existing.map((s) => DateTime(s.date.year, s.date.month, s.date.day)).toSet();

  final entries = [
    for (final date in sorted)
      if (!occupied.contains(date))
        WorkoutSessionsCompanion.insert(date: date, status: const Value(SessionStatus.rest)),
  ];
  if (entries.isNotEmpty) {
    await db.workoutSessionsDao.createSessions(entries);
  }
  return entries.length;
}
