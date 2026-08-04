import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/exercises_table.dart';
import '../tables/personal_records_table.dart';

part 'personal_records_dao.g.dart';

typedef PersonalRecordWithExercise = ({PersonalRecord record, String exerciseName});

@DriftAccessor(tables: [PersonalRecords, Exercises])
class PersonalRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$PersonalRecordsDaoMixin {
  PersonalRecordsDao(super.db);

  // Best (highest value) record per exercise+type, newest first, joined with
  // the exercise name for a global "personal records" list screen.
  Stream<List<PersonalRecordWithExercise>> watchAllBest() {
    final query = select(personalRecords).join([
      innerJoin(exercises, exercises.id.equalsExp(personalRecords.exerciseId)),
    ])
      ..orderBy([OrderingTerm.desc(personalRecords.achievedAt)]);

    return query.watch().map((rows) {
      final best = <String, PersonalRecordWithExercise>{};
      for (final row in rows) {
        final record = row.readTable(personalRecords);
        final exerciseName = row.readTable(exercises).name;
        final key = '${record.exerciseId}-${record.type.index}';
        final current = best[key];
        if (current == null || record.value > current.record.value) {
          best[key] = (record: record, exerciseName: exerciseName);
        }
      }
      final list = best.values.toList()
        ..sort((a, b) => b.record.achievedAt.compareTo(a.record.achievedAt));
      return list;
    });
  }

  Stream<List<PersonalRecord>> watchForExercise(int exerciseId) {
    return (select(personalRecords)
          ..where((p) => p.exerciseId.equals(exerciseId))
          ..orderBy([(p) => OrderingTerm.desc(p.achievedAt)]))
        .watch();
  }

  Future<PersonalRecord?> currentBest(int exerciseId, PersonalRecordType type) {
    return (select(personalRecords)
          ..where((p) => p.exerciseId.equals(exerciseId) & p.type.equalsValue(type))
          ..orderBy([(p) => OrderingTerm.desc(p.value)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> insert(PersonalRecordsCompanion entry) => into(personalRecords).insert(entry);

  Future<int> countAchievedInRange(DateTime start, DateTime end) async {
    final rows = await (select(personalRecords)
          ..where((p) =>
              p.achievedAt.isBiggerOrEqualValue(start) & p.achievedAt.isSmallerThanValue(end)))
        .get();
    return rows.length;
  }
}
