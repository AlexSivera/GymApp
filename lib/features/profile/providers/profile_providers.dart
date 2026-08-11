import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/daos/personal_records_dao.dart' show PersonalRecordWithExercise;
import '../../../data/database/database_provider.dart';

final _bodyWeightDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).bodyWeightDao,
);

final bodyWeightHistoryProvider = StreamProvider<List<BodyWeightLog>>((ref) {
  return ref.watch(_bodyWeightDaoProvider).watchHistory();
});

final latestBodyWeightProvider = StreamProvider<BodyWeightLog?>((ref) {
  return ref.watch(_bodyWeightDaoProvider).watchLatest();
});

final _personalRecordsDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).personalRecordsDao,
);

final allPersonalRecordsProvider = StreamProvider<List<PersonalRecordWithExercise>>((ref) {
  return ref.watch(_personalRecordsDaoProvider).watchAllBest();
});

final _workoutSessionsDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).workoutSessionsDao,
);

final totalWorkoutsCompletedProvider = StreamProvider<int>((ref) {
  return ref
      .watch(_workoutSessionsDaoProvider)
      .watchRecentCompletedSessions(limit: 100000)
      .map((sessions) => sessions.length);
});
