// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'z_state_dao.dart';

// ignore_for_file: type=lint
mixin _$ZStateDaoMixin on DatabaseAccessor<AppDatabase> {
  $ZKeyValuesTable get zKeyValues => attachedDatabase.zKeyValues;
  ZStateDaoManager get managers => ZStateDaoManager(this);
}

class ZStateDaoManager {
  final _$ZStateDaoMixin _db;
  ZStateDaoManager(this._db);
  $$ZKeyValuesTableTableManager get zKeyValues =>
      $$ZKeyValuesTableTableManager(_db.attachedDatabase, _db.zKeyValues);
}
