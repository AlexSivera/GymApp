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
        routineId: routineId,
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

    test('does not overwrite a date that already has a session', () async {
      final routineId = await createRoutineWithDays(['Full body']);
      await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
        date: DateTime(2026, 8, 3),
        status: const Value(SessionStatus.completed),
      ));

      await bulkAssignRoutine(
        db,
        routineId: routineId,
        startDate: DateTime(2026, 8, 3),
        endDate: DateTime(2026, 8, 3),
      );

      final sessions = await db.workoutSessionsDao
          .watchSessionsInRange(DateTime(2026, 8, 3), DateTime(2026, 8, 4))
          .first;
      expect(sessions.length, 1);
      expect(sessions.single.status, SessionStatus.completed);
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
