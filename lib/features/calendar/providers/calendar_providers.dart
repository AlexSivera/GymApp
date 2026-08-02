import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';

final _workoutSessionsDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).workoutSessionsDao,
);

final selectedDayProvider = StateProvider<DateTime>((ref) => _dateOnly(DateTime.now()));

final focusedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

// All sessions in the month currently shown, used to draw calendar markers.
final sessionsInVisibleMonthProvider = StreamProvider<List<WorkoutSession>>((ref) {
  final focusedMonth = ref.watch(focusedMonthProvider);
  final start = DateTime(focusedMonth.year, focusedMonth.month - 1, 1);
  final end = DateTime(focusedMonth.year, focusedMonth.month + 2, 1);
  return ref.watch(_workoutSessionsDaoProvider).watchSessionsInRange(start, end);
});

final sessionForSelectedDayProvider = StreamProvider<WorkoutSession?>((ref) {
  final day = ref.watch(selectedDayProvider);
  return ref.watch(_workoutSessionsDaoProvider).watchSessionForDate(day);
});

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
