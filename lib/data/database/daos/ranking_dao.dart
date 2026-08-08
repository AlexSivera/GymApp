import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/exercise_rank_acknowledgements_table.dart';

part 'ranking_dao.g.dart';

@DriftAccessor(tables: [ExerciseRankAcknowledgements])
class RankingDao extends DatabaseAccessor<AppDatabase> with _$RankingDaoMixin {
  RankingDao(super.db);

  Stream<List<ExerciseRankAcknowledgement>> watchAcknowledged() {
    return select(exerciseRankAcknowledgements).watch();
  }

  Future<void> acknowledge(int exerciseId, int tierIndex, int subTier) {
    return into(exerciseRankAcknowledgements).insertOnConflictUpdate(
      ExerciseRankAcknowledgementsCompanion.insert(
        exerciseId: Value(exerciseId),
        tierIndex: tierIndex,
        subTier: subTier,
      ),
    );
  }
}
