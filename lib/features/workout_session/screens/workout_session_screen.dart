import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/exercise_thumbnail.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/insights_engine/session_summary.dart';
import '../../exercise_library/providers/exercise_library_providers.dart';
import '../../exercise_library/screens/exercise_library_screen.dart';
import '../../routines/providers/routines_providers.dart';
import '../providers/workout_session_providers.dart';
import 'exercise_logging_screen.dart';
import 'session_summary_screen.dart';

class WorkoutSessionScreen extends ConsumerWidget {
  const WorkoutSessionScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

        final dayName = session.routineDayId != null
            ? ref.watch(routineDayByIdProvider(session.routineDayId!)).valueOrNull?.name
            : null;
        final routineExercises = session.routineDayId == null
            ? const <RoutineExercise>[]
            : ref.watch(dayExercisesProvider(session.routineDayId!)).valueOrNull ?? const [];
        final targetsByExercise = {
          for (final re in routineExercises)
            re.exerciseId: (
              restSeconds: re.restSeconds ?? 90,
              repsMin: re.targetRepsMin,
              repsMax: re.targetRepsMax,
              sets: re.targetSets,
            ),
        };

        return sessionExercisesAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
          data: (sessionExercises) {
            final completedCount = sessionExercises
                .where((e) =>
                    e.status == SessionExerciseStatus.completed ||
                    e.status == SessionExerciseStatus.skipped)
                .length;
            final allDone = sessionExercises.isNotEmpty && completedCount == sessionExercises.length;

            return Scaffold(
              appBar: AppBar(
                title: Text(dayName ?? 'Entrenamiento libre'),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => _addExercise(context, ref, sessionExercises.length),
                child: const Icon(Icons.add),
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(child: _ElapsedTime(startedAt: session.startedAt)),
                        Text(
                          '$completedCount de ${sessionExercises.length} ejercicios',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (allDone)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: AppCard(
                        child: Row(
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text('¡Entrenamiento completado!',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: sessionExercises.isEmpty
                        ? Center(
                            child: Text(
                              'Añade un ejercicio con el botón +.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxxl),
                            itemCount: sessionExercises.length,
                            onReorderItem: (oldIndex, newIndex) =>
                                _reorder(ref, sessionExercises, oldIndex, newIndex),
                            itemBuilder: (context, index) {
                              final sessionExercise = sessionExercises[index];
                              final exercise = exercisesById[sessionExercise.exerciseId];
                              return Padding(
                                key: ValueKey(sessionExercise.id),
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: _ExerciseRow(
                                  sessionId: sessionId,
                                  sessionExercise: sessionExercise,
                                  exerciseName: exercise?.name ?? 'Ejercicio',
                                  imagePaths: exercise?.imagePaths ?? const [],
                                  targets: targetsByExercise[sessionExercise.exerciseId],
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _completeSession(context, ref, session),
                        child: const Text('Finalizar entrenamiento'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _reorder(
    WidgetRef ref,
    List<SessionExercise> current,
    int oldIndex,
    int newIndex,
  ) async {
    final list = [...current];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await ref.read(sessionLoggingDaoProvider).reorderSessionExercises(list.map((e) => e.id).toList());
  }

  Future<void> _completeSession(BuildContext context, WidgetRef ref, WorkoutSession session) async {
    final db = ref.read(appDatabaseProvider);
    final durationSeconds = session.startedAt != null
        ? DateTime.now().difference(session.startedAt!).inSeconds
        : null;
    await db.workoutSessionsDao.updateSession(
      session.copyWith(
        status: SessionStatus.completed,
        completedAt: Value(DateTime.now()),
        durationSeconds: Value(durationSeconds),
      ),
    );

    final summary = await computeSessionSummary(db, sessionId: sessionId);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SessionSummaryScreen(summary: summary)),
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

class _ElapsedTime extends StatefulWidget {
  const _ElapsedTime({required this.startedAt});

  final DateTime? startedAt;

  @override
  State<_ElapsedTime> createState() => _ElapsedTimeState();
}

class _ElapsedTimeState extends State<_ElapsedTime> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.startedAt != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startedAt = widget.startedAt;
    if (startedAt == null) return const SizedBox.shrink();
    final elapsed = DateTime.now().difference(startedAt);
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final hours = elapsed.inHours;
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final text = hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

typedef _ExerciseTargets = ({int restSeconds, int repsMin, int repsMax, int sets});

class _ExerciseRow extends ConsumerWidget {
  const _ExerciseRow({
    required this.sessionId,
    required this.sessionExercise,
    required this.exerciseName,
    required this.imagePaths,
    required this.targets,
  });

  final int sessionId;
  final SessionExercise sessionExercise;
  final String exerciseName;
  final List<String> imagePaths;
  final _ExerciseTargets? targets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(setsForExerciseProvider(sessionExercise.id)).valueOrNull ?? const [];
    final isDone = sessionExercise.status == SessionExerciseStatus.completed ||
        sessionExercise.status == SessionExerciseStatus.skipped;

    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: ExerciseThumbnail(imagePaths: imagePaths),
        title: Text(exerciseName),
        subtitle: Text(_setsSummary(sets)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusIcon(status: sessionExercise.status),
            Checkbox(
              value: isDone,
              activeColor: AppTheme.statusCompleted,
              onChanged: (checked) => _toggleDone(ref, checked ?? false),
            ),
          ],
        ),
        onTap: () => _openExercise(context, ref),
      ),
    );
  }

  Future<void> _toggleDone(WidgetRef ref, bool checked) async {
    await ref.read(sessionLoggingDaoProvider).updateSessionExerciseStatus(
          sessionExercise.id,
          checked ? SessionExerciseStatus.completed : SessionExerciseStatus.pending,
        );
  }

  void _openExercise(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExerciseLoggingScreen(
        sessionExerciseId: sessionExercise.id,
        exerciseId: sessionExercise.exerciseId,
        sessionId: sessionId,
        exerciseName: exerciseName,
        restSeconds: targets?.restSeconds ?? 90,
        targetRepsMin: targets?.repsMin ?? 8,
        targetRepsMax: targets?.repsMax ?? 12,
        targetSets: targets?.sets,
      ),
    ));
  }

  String _setsSummary(List<WorkoutSet> sets) {
    if (sets.isEmpty) return 'Sin series todavía';
    final valid = sets.where((s) => s.weightKg != null && s.reps != null).toList();
    if (valid.isEmpty) return '${sets.length} serie${sets.length == 1 ? '' : 's'}';
    final parts = valid.take(3).map((s) => '${_fmt(s.weightKg!)}×${s.reps}');
    final suffix = valid.length > 3 ? ' +${valid.length - 3}' : '';
    return '${parts.join(' · ')}$suffix kg';
  }

  String _fmt(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final SessionExerciseStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SessionExerciseStatus.pending:
        return const Icon(Icons.crop_square, size: 20, color: AppTheme.statusEmpty);
      case SessionExerciseStatus.inProgress:
        return const Icon(Icons.circle, size: 12, color: AppTheme.statusPlanned);
      case SessionExerciseStatus.completed:
        return const Icon(Icons.check_circle, size: 20, color: AppTheme.statusCompleted);
      case SessionExerciseStatus.skipped:
        return const Icon(Icons.remove_circle, size: 20, color: AppTheme.statusSkipped);
    }
  }
}
