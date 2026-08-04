import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/body_weight_logs_table.dart';

part 'body_weight_dao.g.dart';

@DriftAccessor(tables: [BodyWeightLogs])
class BodyWeightDao extends DatabaseAccessor<AppDatabase>
    with _$BodyWeightDaoMixin {
  BodyWeightDao(super.db);

  Stream<BodyWeightLog?> watchLatest() {
    return (select(bodyWeightLogs)
          ..orderBy([(w) => OrderingTerm.desc(w.date)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Stream<List<BodyWeightLog>> watchHistory({int limit = 90}) {
    return (select(bodyWeightLogs)
          ..orderBy([(w) => OrderingTerm.desc(w.date)])
          ..limit(limit))
        .watch();
  }

  Future<int> insertLog(BodyWeightLogsCompanion entry) {
    return into(bodyWeightLogs).insert(entry);
  }

  Future<int> deleteLog(int id) {
    return (delete(bodyWeightLogs)..where((w) => w.id.equals(id))).go();
  }
}
