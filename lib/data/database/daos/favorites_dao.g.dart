// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_dao.dart';

// ignore_for_file: type=lint
mixin _$FavoritesDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $FavoriteExercisesTable get favoriteExercises =>
      attachedDatabase.favoriteExercises;
  FavoritesDaoManager get managers => FavoritesDaoManager(this);
}

class FavoritesDaoManager {
  final _$FavoritesDaoMixin _db;
  FavoritesDaoManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$FavoriteExercisesTableTableManager get favoriteExercises =>
      $$FavoriteExercisesTableTableManager(
        _db.attachedDatabase,
        _db.favoriteExercises,
      );
}
