import 'package:drift/drift.dart';

// GymZ's own small state (wishes granted by Shenlong, sound on/off, the
// chosen title and aura, one-off easter eggs…) as plain key/value rows.
// Kept out of UserSettings on purpose: backups made with Machoke restore
// into GymZ unchanged, since UserSetting's JSON shape doesn't move.
class ZKeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
