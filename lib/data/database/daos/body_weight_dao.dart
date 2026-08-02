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
}
