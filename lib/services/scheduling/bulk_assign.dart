import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';

// Fills [startDate]..[endDate] (inclusive) with planned sessions, cycling
// through [routineIds] in the given order and skipping [restWeekdays]
// (DateTime.weekday values, 1=Monday..7=Sunday).
//
// Routines are single-day now (Push, Pull, Legs are separate routines
// instead of days nested under one), so the rotation is built by
// concatenating each selected routine's day(s) in the order they were
// picked — Push's day, then Pull's, then Legs' — rather than the days of a
// single routine like before. A routine with more than one day (from
// before that change) still contributes all of them, in order.
//
// Re-running this over an already-planned range replaces that plan instead
// of silently doing nothing (the previous behavior skipped any occupied
// date, so fixing a wrong quick-assign meant it never took effect). Days
// already completed, skipped, or in progress are real training history and
// are left untouched either way — only `planned`/`rest` placeholders get
// overwritten.
Future<int> bulkAssignRoutine(
  AppDatabase db, {
  required List<int> routineIds,
  required DateTime startDate,
  required DateTime endDate,
  Set<int> restWeekdays = const {},
}) async {
  final days = <RoutineDay>[];
  for (final routineId in routineIds) {
    days.addAll(await db.routinesDao.watchDays(routineId).first);
  }
  if (days.isEmpty) return 0;

  final start = DateTime(startDate.year, startDate.month, startDate.day);
  final end = DateTime(endDate.year, endDate.month, endDate.day);
  final existing = await db.workoutSessionsDao
      .watchSessionsInRange(start, end.add(const Duration(days: 1)))
      .first;

  const protectedStatuses = {
    SessionStatus.completed,
    SessionStatus.skipped,
    SessionStatus.inProgress,
  };
  final protectedDates = <DateTime>{};
  final overwritableIds = <int>[];
  for (final s in existing) {
    final date = DateTime(s.date.year, s.date.month, s.date.day);
    if (protectedStatuses.contains(s.status)) {
      protectedDates.add(date);
    } else {
      overwritableIds.add(s.id);
    }
  }
  if (overwritableIds.isNotEmpty) {
    await db.workoutSessionsDao.deleteSessions(overwritableIds);
  }

  final entries = <WorkoutSessionsCompanion>[];
  var cursor = start;
  var dayIndex = 0;

  while (!cursor.isAfter(end)) {
    if (!protectedDates.contains(cursor)) {
      final isRestDay = restWeekdays.contains(cursor.weekday);
      if (isRestDay) {
        entries.add(WorkoutSessionsCompanion.insert(
          date: cursor,
          status: const Value(SessionStatus.rest),
        ));
      } else {
        final routineDay = days[dayIndex % days.length];
        entries.add(WorkoutSessionsCompanion.insert(
          date: cursor,
          routineDayId: Value(routineDay.id),
          status: const Value(SessionStatus.planned),
        ));
        dayIndex++;
      }
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
