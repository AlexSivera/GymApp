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
