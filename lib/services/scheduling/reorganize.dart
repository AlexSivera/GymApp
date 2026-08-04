import '../../data/database/app_database.dart';

enum ReorganizeAction { markMissed, moveToNextDay, shiftFollowingChain }

// Handles a `planned` session whose date has already passed without being
// started, offering the 3 choices from the calendar's day-detail sheet.
Future<void> reorganizeMissedSession(
  AppDatabase db, {
  required WorkoutSession session,
  required ReorganizeAction action,
}) async {
  switch (action) {
    case ReorganizeAction.markMissed:
      await db.workoutSessionsDao.updateSession(
        session.copyWith(status: SessionStatus.skipped),
      );
    case ReorganizeAction.moveToNextDay:
      await db.workoutSessionsDao.updateSession(
        session.copyWith(date: session.date.add(const Duration(days: 1))),
      );
    case ReorganizeAction.shiftFollowingChain:
      await _shiftChainForward(db, session);
  }
}

// Shifts [missed] and every contiguous following `planned` session (no gap
// day in between) forward by one day, preserving their relative order.
// e.g. Mon Push (missed) / Tue Pull / Wed Legs becomes
//      Tue Push / Wed Pull / Thu Legs.
Future<void> _shiftChainForward(AppDatabase db, WorkoutSession missed) async {
  final upcoming = await db.workoutSessionsDao.getPlannedSessionsFrom(missed.date);

  final chain = <WorkoutSession>[];
  DateTime? expectedDate;
  for (final s in upcoming) {
    final day = DateTime(s.date.year, s.date.month, s.date.day);
    if (expectedDate == null || day == expectedDate) {
      chain.add(s);
      expectedDate = day.add(const Duration(days: 1));
    } else {
      break;
    }
  }

  // Shift from the last entry backwards so no date is overwritten mid-loop.
  for (final s in chain.reversed) {
    await db.workoutSessionsDao.updateSession(
      s.copyWith(date: s.date.add(const Duration(days: 1))),
    );
  }
}
