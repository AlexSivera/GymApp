import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/data/database/app_database.dart';
import 'package:gymapp/services/scheduling/bulk_assign.dart';
import 'package:gymapp/services/scheduling/reorganize.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> createRoutineWithDays(List<String> dayNames) async {
    final routineId =
        await db.routinesDao.createRoutine(RoutinesCompanion.insert(name: 'Test routine'));
    for (var i = 0; i < dayNames.length; i++) {
      await db.routinesDao
          .createDay(RoutineDaysCompanion.insert(routineId: routineId, name: dayNames[i], dayOrder: i));
    }
    return routineId;
  }

  group('bulkAssignRoutine', () {
    test('cycles through routine days and skips rest weekdays', () async {
      final routineId = await createRoutineWithDays(['Push', 'Pull', 'Legs']);
      // Monday 2026-08-03 .. Sunday 2026-08-09, resting on weekends (6, 7).
      final created = await bulkAssignRoutine(
        db,
        routineIds: [routineId],
        startDate: DateTime(2026, 8, 3),
        endDate: DateTime(2026, 8, 9),
        restWeekdays: {DateTime.saturday, DateTime.sunday},
      );

      expect(created, 7); // 5 training days + 2 rest-day placeholders.
      final sessions = await db.workoutSessionsDao
          .watchSessionsInRange(DateTime(2026, 8, 3), DateTime(2026, 8, 10))
          .first;
      expect(sessions.length, 7);

      final restDays = sessions.where((s) => s.status == SessionStatus.rest);
      expect(restDays.length, 2);
      final plannedDays = sessions.where((s) => s.status == SessionStatus.planned);
      expect(plannedDays.length, 5);
    });

    test('cycles through several single-day routines in the given order', () async {
      // Push/Pull/Legs as three separate single-day routines (today's model)
      // instead of one routine with three days (the old, no-longer-possible
      // shape the previous test still exercises for regression coverage).
      final pushId = await createRoutineWithDays(['Push']);
      final pullId = await createRoutineWithDays(['Pull']);
      final legsId = await createRoutineWithDays(['Legs']);
      final pushDayId = (await db.routinesDao.watchDays(pushId).first).single.id;
      final pullDayId = (await db.routinesDao.watchDays(pullId).first).single.id;
      final legsDayId = (await db.routinesDao.watchDays(legsId).first).single.id;

      // Monday 2026-08-03 .. Friday 2026-08-07, no rest days.
      await bulkAssignRoutine(
        db,
        routineIds: [pushId, pullId, legsId],
        startDate: DateTime(2026, 8, 3),
        endDate: DateTime(2026, 8, 7),
      );

      final sessions = await db.workoutSessionsDao
          .watchSessionsInRange(DateTime(2026, 8, 3), DateTime(2026, 8, 8))
          .first;
      final orderedDayIds = (sessions.toList()..sort((a, b) => a.date.compareTo(b.date)))
          .map((s) => s.routineDayId)
          .toList();
      expect(orderedDayIds, [pushDayId, pullDayId, legsDayId, pushDayId, pullDayId]);
    });

    test('leaves a completed session untouched', () async {
      final routineId = await createRoutineWithDays(['Full body']);
      await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
        date: DateTime(2026, 8, 3),
        status: const Value(SessionStatus.completed),
      ));

      await bulkAssignRoutine(
        db,
        routineIds: [routineId],
        startDate: DateTime(2026, 8, 3),
        endDate: DateTime(2026, 8, 3),
      );

      final sessions = await db.workoutSessionsDao
          .watchSessionsInRange(DateTime(2026, 8, 3), DateTime(2026, 8, 4))
          .first;
      expect(sessions.length, 1);
      expect(sessions.single.status, SessionStatus.completed);
    });

    test('re-running over an already-planned range replaces the old plan', () async {
      final oldRoutineId = await createRoutineWithDays(['Old routine']);
      final newRoutineId = await createRoutineWithDays(['New routine']);
      final newDayId = (await db.routinesDao.watchDays(newRoutineId).first).single.id;

      await bulkAssignRoutine(
        db,
        routineIds: [oldRoutineId],
        startDate: DateTime(2026, 8, 3),
        endDate: DateTime(2026, 8, 5),
      );

      await bulkAssignRoutine(
        db,
        routineIds: [newRoutineId],
        startDate: DateTime(2026, 8, 3),
        endDate: DateTime(2026, 8, 5),
      );

      final sessions = await db.workoutSessionsDao
          .watchSessionsInRange(DateTime(2026, 8, 3), DateTime(2026, 8, 6))
          .first;
      expect(sessions.length, 3); // replaced in place, not duplicated
      expect(sessions.every((s) => s.routineDayId == newDayId), isTrue);
    });
  });

  group('reorganizeMissedSession', () {
    test('shiftFollowingChain moves the missed session and the contiguous chain forward', () async {
      final routineId = await createRoutineWithDays(['Push', 'Pull', 'Legs']);
      final days = await db.routinesDao.watchDays(routineId).first;

      final mondayId = await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
        date: DateTime(2026, 8, 3),
        routineDayId: Value(days[0].id),
        status: const Value(SessionStatus.planned),
      ));
      await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
        date: DateTime(2026, 8, 4),
        routineDayId: Value(days[1].id),
        status: const Value(SessionStatus.planned),
      ));
      await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
        date: DateTime(2026, 8, 5),
        routineDayId: Value(days[2].id),
        status: const Value(SessionStatus.planned),
      ));

      final monday = await db.workoutSessionsDao.watchById(mondayId).first;
      await reorganizeMissedSession(db, session: monday!, action: ReorganizeAction.shiftFollowingChain);

      final sessions = await db.workoutSessionsDao
          .watchSessionsInRange(DateTime(2026, 8, 3), DateTime(2026, 8, 7))
          .first
        ..sort((a, b) => a.date.compareTo(b.date));

      expect(sessions.length, 3);
      expect(sessions[0].date, DateTime(2026, 8, 4));
      expect(sessions[0].routineDayId, days[0].id);
      expect(sessions[1].date, DateTime(2026, 8, 5));
      expect(sessions[1].routineDayId, days[1].id);
      expect(sessions[2].date, DateTime(2026, 8, 6));
      expect(sessions[2].routineDayId, days[2].id);
    });

    test('markMissed sets status to skipped', () async {
      final id = await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
        date: DateTime(2026, 8, 3),
        status: const Value(SessionStatus.planned),
      ));
      final session = await db.workoutSessionsDao.watchById(id).first;
      await reorganizeMissedSession(db, session: session!, action: ReorganizeAction.markMissed);

      final updated = await db.workoutSessionsDao.watchById(id).first;
      expect(updated!.status, SessionStatus.skipped);
    });

    test('moveToNextDay shifts only the given session by one day', () async {
      final id = await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
        date: DateTime(2026, 8, 3),
        status: const Value(SessionStatus.planned),
      ));
      final session = await db.workoutSessionsDao.watchById(id).first;
      await reorganizeMissedSession(db, session: session!, action: ReorganizeAction.moveToNextDay);

      final updated = await db.workoutSessionsDao.watchById(id).first;
      expect(updated!.date, DateTime(2026, 8, 4));
    });
  });
}
