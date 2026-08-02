import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';
import 'estimated_one_rep_max.dart';

// Compares a just-logged set against the exercise's existing best records and
// inserts a new PersonalRecord row for each type it beats. Returns the types
// that were newly achieved, for UI feedback (e.g. a "new PR!" message).
Future<List<PersonalRecordType>> checkAndRecordPRs(
  AppDatabase db, {
  required int exerciseId,
  required int setId,
  required double weightKg,
  required int reps,
}) async {
  final dao = db.personalRecordsDao;
  final achieved = <PersonalRecordType>[];

  Future<void> checkType(PersonalRecordType type, double value) async {
    final existing = await dao.currentBest(exerciseId, type);
    if (existing == null || value > existing.value) {
      await dao.insert(PersonalRecordsCompanion.insert(
        exerciseId: exerciseId,
        type: type,
        value: value,
        reps: Value(reps),
        achievedAt: DateTime.now(),
        setId: Value(setId),
      ));
      achieved.add(type);
    }
  }

  await checkType(PersonalRecordType.maxWeight, weightKg);
  await checkType(PersonalRecordType.estimatedOneRepMax, estimatedOneRepMax(weightKg, reps));

  return achieved;
}
