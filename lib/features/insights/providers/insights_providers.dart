import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database_provider.dart';
import '../../../services/insights_engine/muscle_balance.dart';
import '../../../services/insights_engine/stagnation.dart';
import '../../../services/insights_engine/weekly_summary.dart';

final weeklySummaryProvider = FutureProvider.autoDispose((ref) {
  return computeWeeklySummary(ref.watch(appDatabaseProvider));
});

final stagnantExercisesProvider = FutureProvider.autoDispose((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final allExercises = await db.exercisesDao.watchAll().first;
  return detectStagnantExercises(db, allExercises: allExercises);
});

final muscleBalanceProvider = FutureProvider.autoDispose((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final allExercises = await db.exercisesDao.watchAll().first;
  return computeMuscleBalance(db, allExercises: allExercises);
});
