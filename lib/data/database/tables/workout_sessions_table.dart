import 'package:drift/drift.dart';

import '../enums.dart';
import 'exercises_table.dart';
import 'routines_table.dart';

class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get routineDayId =>
      integer().nullable().references(RoutineDays, #id)();
  IntColumn get status => intEnum<SessionStatus>()
      .withDefault(Constant(SessionStatus.planned.index))();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  RealColumn get bodyWeightKg => real().nullable()();
  IntColumn get feeling => integer().nullable()();
  TextColumn get notes => text().nullable()();
}

class SessionExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutSessionId =>
      integer().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer()();
  IntColumn get status => intEnum<SessionExerciseStatus>()
      .withDefault(Constant(SessionExerciseStatus.pending.index))();
  TextColumn get notes => text().nullable()();
}

// Named "WorkoutSets" (not "Sets") to avoid colliding with dart:core's Set
// when drift generates the singular row class ("WorkoutSet").
class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionExerciseId => integer()
      .references(SessionExercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get setNumber => integer()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get reps => integer().nullable()();
  RealColumn get rir => real().nullable()();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
}
