import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';

final routinesDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).routinesDao,
);

final routinesListProvider = StreamProvider<List<Routine>>((ref) {
  return ref.watch(routinesDaoProvider).watchAllRoutines();
});

final routineProvider = StreamProvider.family<Routine?, int>((ref, routineId) {
  return ref.watch(routinesDaoProvider).watchRoutine(routineId);
});

final routineDaysProvider = StreamProvider.family<List<RoutineDay>, int>((ref, routineId) {
  return ref.watch(routinesDaoProvider).watchDays(routineId);
});

final dayExercisesProvider = StreamProvider.family<List<RoutineExercise>, int>((ref, routineDayId) {
  return ref.watch(routinesDaoProvider).watchExercisesForDay(routineDayId);
});

final routineDayByIdProvider = StreamProvider.family<RoutineDay?, int>((ref, routineDayId) {
  return ref.watch(routinesDaoProvider).watchDayById(routineDayId);
});

final routineExerciseCountProvider = StreamProvider.family<int, int>((ref, routineId) {
  return ref.watch(routinesDaoProvider).watchExerciseCountInRoutine(routineId);
});

// Which RoutineExercise rows are expanded inline in a routine day's list —
// several can be open at once (e.g. all newly-added exercises after a
// multi-select add).
final expandedRoutineExerciseIdsProvider = StateProvider<Set<int>>((ref) => {});

// What to call a session's routine day across Home/Calendar/Entreno: the
// day's own name when its routine has multiple days (Torso, Pierna...), or
// the routine's name when it's the routine's only day — every routine
// created today has exactly one day named "Día 1" internally, and no screen
// should ever surface that placeholder. Null for a free workout (no day at
// all); callers supply their own fallback text for that case.
final routineDaySessionTitleProvider = Provider.family<String?, int?>((ref, routineDayId) {
  if (routineDayId == null) return null;
  final day = ref.watch(routineDayByIdProvider(routineDayId)).valueOrNull;
  if (day == null) return null;

  final siblingDays = ref.watch(routineDaysProvider(day.routineId)).valueOrNull;
  if (siblingDays != null && siblingDays.length <= 1) {
    return ref.watch(routineProvider(day.routineId)).valueOrNull?.name ?? day.name;
  }
  return day.name;
});
