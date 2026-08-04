import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/user_settings_table.dart';

part 'user_settings_dao.g.dart';

// Single-row table: the app only ever reads/writes the row with id = 1.
@DriftAccessor(tables: [UserSettings])
class UserSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$UserSettingsDaoMixin {
  UserSettingsDao(super.db);

  Future<void> ensureDefaultRow() async {
    final existing = await select(userSettings).getSingleOrNull();
    if (existing == null) {
      await into(userSettings).insert(const UserSettingsCompanion());
    }
  }

  Stream<UserSetting?> watchSettings() {
    return (select(userSettings)..limit(1)).watchSingleOrNull();
  }

  Future<void> updateSettings(UserSettingsCompanion entry) async {
    final existing = await select(userSettings).getSingleOrNull();
    if (existing == null) {
      await into(userSettings).insert(entry);
    } else {
      await (update(userSettings)..where((s) => s.id.equals(existing.id))).write(entry);
    }
  }
}
