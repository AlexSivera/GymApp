import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/daos/progress_dao.dart';
import '../../../data/database/database_provider.dart';

final progressDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).progressDao,
);

final oneRepMaxHistoryProvider =
    FutureProvider.family<List<OneRepMaxPoint>, int>((ref, exerciseId) {
  return ref.watch(progressDaoProvider).estimatedOneRepMaxHistory(exerciseId);
});

final personalRecordsDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).personalRecordsDao,
);

final personalRecordsForExerciseProvider =
    StreamProvider.family<List<PersonalRecord>, int>((ref, exerciseId) {
  return ref.watch(personalRecordsDaoProvider).watchForExercise(exerciseId);
});
