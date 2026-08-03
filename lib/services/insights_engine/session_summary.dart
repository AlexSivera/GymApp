import '../../data/database/app_database.dart';
import '../progression_engine/previous_performance.dart';

class ExerciseImprovement {
  const ExerciseImprovement({required this.exerciseName, required this.message});

  final String exerciseName;
  final String message;
}

class SessionSummary {
  const SessionSummary({
    required this.improvements,
    required this.newPRs,
    required this.volumeThisSession,
    required this.volumeChangePercent,
  });

  final List<ExerciseImprovement> improvements;
  final List<String> newPRs;
  final double volumeThisSession;
  final double? volumeChangePercent;
}

// Compares a just-completed session against prior history to surface
// what improved — meant to be shown right after finishing a workout.
Future<SessionSummary> computeSessionSummary(AppDatabase db, {required int sessionId}) async {
  final session = await db.workoutSessionsDao.watchById(sessionId).first;
  final sessionExercises = await db.sessionLoggingDao.watchSessionExercises(sessionId).first;
  final allExercises = await db.exercisesDao.watchAll().first;
  final exercisesById = {for (final e in allExercises) e.id: e};

  final improvements = <ExerciseImprovement>[];
  final newPRs = <String>{};
  var sessionVolume = 0.0;

  for (final sessionExercise in sessionExercises) {
    final sets = await db.sessionLoggingDao.watchSets(sessionExercise.id).first;
    final validSets = sets.where((s) => s.weightKg != null && s.reps != null).toList();
    if (validSets.isEmpty) continue;

    sessionVolume += validSets.fold(0.0, (sum, s) => sum + s.weightKg! * s.reps!);
    final exerciseName = exercisesById[sessionExercise.exerciseId]?.name ?? 'Ejercicio';

    final previousSets = await getPreviousSetsForExercise(
      db,
      exerciseId: sessionExercise.exerciseId,
      excludeSessionId: sessionId,
    );
    final previousWeights = previousSets.map((s) => s.weightKg).whereType<double>();
    if (previousWeights.isNotEmpty) {
      final prevBest = previousWeights.reduce((a, b) => a > b ? a : b);
      final currentBest =
          validSets.map((s) => s.weightKg!).reduce((a, b) => a > b ? a : b);
      if (currentBest > prevBest) {
        improvements.add(ExerciseImprovement(
          exerciseName: exerciseName,
          message: '+${(currentBest - prevBest).toStringAsFixed(1)} kg',
        ));
      }
    }

    final prRecords = await db.personalRecordsDao.watchForExercise(sessionExercise.exerciseId).first;
    final gotPR = validSets.any((set) => prRecords.any((r) => r.setId == set.id));
    if (gotPR) newPRs.add(exerciseName);
  }

  double? volumeChangePercent;
  if (session != null && session.routineDayId != null) {
    final previousSessions = await db.workoutSessionsDao.getLastCompletedSessionForRoutineDay(
      session.routineDayId!,
      excludeSessionId: sessionId,
    );
    if (previousSessions.isNotEmpty) {
      final prevDate = previousSessions.first.date;
      final prevVolume = await db.progressDao
          .totalVolumeInRange(prevDate, prevDate.add(const Duration(days: 1)));
      if (prevVolume > 0) {
        volumeChangePercent = (sessionVolume - prevVolume) / prevVolume * 100;
      }
    }
  }

  return SessionSummary(
    improvements: improvements,
    newPRs: newPRs.toList(),
    volumeThisSession: sessionVolume,
    volumeChangePercent: volumeChangePercent,
  );
}
