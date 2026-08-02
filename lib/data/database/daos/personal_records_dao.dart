import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/personal_records_table.dart';

part 'personal_records_dao.g.dart';

@DriftAccessor(tables: [PersonalRecords])
class PersonalRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$PersonalRecordsDaoMixin {
  PersonalRecordsDao(super.db);

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
}
