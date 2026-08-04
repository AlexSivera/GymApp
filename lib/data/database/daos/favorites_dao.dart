import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/favorite_exercises_table.dart';

part 'favorites_dao.g.dart';

@DriftAccessor(tables: [FavoriteExercises])
class FavoritesDao extends DatabaseAccessor<AppDatabase>
    with _$FavoritesDaoMixin {
  FavoritesDao(super.db);

  Stream<List<int>> watchFavoriteExerciseIds() {
    final query = selectOnly(favoriteExercises)
      ..addColumns([favoriteExercises.exerciseId]);
    return query
        .watch()
        .map((rows) => rows.map((r) => r.read(favoriteExercises.exerciseId)!).toList());
  }

  Future<void> toggleFavorite(int exerciseId) async {
    final existing = await (select(favoriteExercises)
          ..where((f) => f.exerciseId.equals(exerciseId)))
        .getSingleOrNull();
    if (existing == null) {
      await into(favoriteExercises)
          .insert(FavoriteExercisesCompanion.insert(exerciseId: exerciseId));
    } else {
      await (delete(favoriteExercises)..where((f) => f.id.equals(existing.id))).go();
    }
  }
}
