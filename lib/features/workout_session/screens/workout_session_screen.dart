import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../exercise_library/providers/exercise_library_providers.dart';
import '../../exercise_library/screens/exercise_library_screen.dart';
import '../../routines/providers/routines_providers.dart';
import '../providers/workout_session_providers.dart';
import 'exercise_logging_screen.dart';

class WorkoutSessionScreen extends ConsumerWidget {
  const WorkoutSessionScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sessionAsync = ref.watch(sessionByIdProvider(sessionId));
    final sessionExercisesAsync = ref.watch(sessionExercisesProvider(sessionId));
    final allExercises = ref.watch(allExercisesProvider).valueOrNull ?? const [];
    final exercisesById = {for (final e in allExercises) e.id: e};

    return sessionAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (session) {
        if (session == null) {
          return const Scaffold(body: Center(child: Text('Entrenamiento no encontrado')));
        }

        final routineExercises = session.routineDayId == null
            ? const <RoutineExercise>[]
            : ref.watch(dayExercisesProvider(session.routineDayId!)).valueOrNull ?? const [];
        final restSecondsByExercise = {
          for (final re in routineExercises) re.exerciseId: re.restSeconds ?? 90,
        };
        final repsRangeByExercise = {
          for (final re in routineExercises) re.exerciseId: (re.targetRepsMin, re.targetRepsMax),
        };

        return Scaffold(
          appBar: AppBar(
            title: Text(DateFormat('EEEE d MMMM', 'es').format(session.date)),
            actions: [
              if (session.status != SessionStatus.completed)
                TextButton(
                  onPressed: () => _completeSession(ref, session),
                  child: const Text('Completar'),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
                _addExercise(context, ref, sessionExercisesAsync.valueOrNull?.length ?? 0),
            child: const Icon(Icons.add),
          ),
          body: sessionExercisesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (sessionExercises) {
              if (sessionExercises.isEmpty) {
                return Center(
                  child: Text(
                    'Añade un ejercicio con el botón +.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sessionExercises.length,
                itemBuilder: (context, index) {
                  final sessionExercise = sessionExercises[index];
                  final exercise = exercisesById[sessionExercise.exerciseId];
                  final exerciseName = exercise?.name ?? 'Ejercicio';
                  final sets = ref.watch(setsForExerciseProvider(sessionExercise.id)).valueOrNull;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        title: Text(exerciseName),
                        subtitle: Text(sets == null || sets.isEmpty
                            ? 'Sin series todavía'
                            : '${sets.length} serie${sets.length == 1 ? '' : 's'} registrada${sets.length == 1 ? '' : 's'}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final repsRange = repsRangeByExercise[sessionExercise.exerciseId];
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ExerciseLoggingScreen(
                              sessionExerciseId: sessionExercise.id,
                              exerciseId: sessionExercise.exerciseId,
                              sessionId: sessionId,
                              exerciseName: exerciseName,
                              restSeconds: restSecondsByExercise[sessionExercise.exerciseId] ?? 90,
                              targetRepsMin: repsRange?.$1 ?? 8,
                              targetRepsMax: repsRange?.$2 ?? 12,
                            ),
                          ));
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _completeSession(WidgetRef ref, WorkoutSession session) async {
    await ref.read(appDatabaseProvider).workoutSessionsDao.updateSession(
          session.copyWith(
            status: SessionStatus.completed,
            completedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref, int currentCount) async {
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen(pickerMode: true)),
    );
    if (exercise == null) return;
    await ref.read(sessionLoggingDaoProvider).addSessionExercise(SessionExercisesCompanion.insert(
          workoutSessionId: sessionId,
          exerciseId: exercise.id,
          orderIndex: currentCount,
        ));
  }
}
