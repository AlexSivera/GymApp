// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking_dao.dart';

// ignore_for_file: type=lint
mixin _$RankingDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExerciseRankAcknowledgementsTable get exerciseRankAcknowledgements =>
      attachedDatabase.exerciseRankAcknowledgements;
  RankingDaoManager get managers => RankingDaoManager(this);
}

class RankingDaoManager {
  final _$RankingDaoMixin _db;
  RankingDaoManager(this._db);
  $$ExerciseRankAcknowledgementsTableTableManager
  get exerciseRankAcknowledgements =>
      $$ExerciseRankAcknowledgementsTableTableManager(
        _db.attachedDatabase,
        _db.exerciseRankAcknowledgements,
      );
}
