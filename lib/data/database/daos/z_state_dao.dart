import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/z_key_values_table.dart';

part 'z_state_dao.g.dart';

@DriftAccessor(tables: [ZKeyValues])
class ZStateDao extends DatabaseAccessor<AppDatabase> with _$ZStateDaoMixin {
  ZStateDao(super.db);

  Stream<Map<String, String>> watchAll() {
    return select(zKeyValues).watch().map((rows) => {for (final row in rows) row.key: row.value});
  }

  Future<String?> read(String key) async {
    final row = await (select(zKeyValues)..where((r) => r.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> write(String key, String value) {
    return into(zKeyValues).insertOnConflictUpdate(ZKeyValuesCompanion.insert(key: key, value: value));
  }
}
