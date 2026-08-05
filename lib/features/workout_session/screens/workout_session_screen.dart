import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/exercise_thumbnail.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/insights_engine/session_summary.dart';
import '../../../services/progression_engine/check_and_record_prs.dart';
import '../../../services/progression_engine/previous_performance.dart';
import '../../../services/progression_engine/suggest_next_load.dart';
import '../../exercise_library/providers/exercise_library_providers.dart';
import '../../exercise_library/screens/exercise_library_screen.dart';
import '../../routines/providers/routines_providers.dart';
import '../providers/rest_timer_controller.dart';
import '../providers/workout_session_providers.dart';
import '../widgets/rest_timer_banner.dart';
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
              bottomNavigationBar: const RestTimerBanner(),
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
enum _ExerciseMenuAction { history, notes, skip }

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
    final isExpanded = ref.watch(expandedSessionExerciseIdProvider) == sessionExercise.id;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: ExerciseThumbnail(imagePaths: imagePaths),
            title: Text(exerciseName),
            subtitle: Text(_setsSummary(sets)),
            trailing: _StatusIcon(status: sessionExercise.status),
            onTap: () => _toggleExpanded(ref, sets),
          ),
          AnimatedSize(
            duration: AppMotion.normal,
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? _ExpandedExerciseDetail(
                    sessionId: sessionId,
                    sessionExercise: sessionExercise,
                    exerciseName: exerciseName,
                    targets: targets,
                    sets: sets,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  // Opening a routine-backed exercise for the first time pre-creates all of
  // its target sets (prefilled from last time / the suggested weight) so
  // the checklist matches the plan immediately, instead of starting empty.
  Future<void> _toggleExpanded(WidgetRef ref, List<WorkoutSet> currentSets) async {
    final notifier = ref.read(expandedSessionExerciseIdProvider.notifier);
    final opening = notifier.state != sessionExercise.id;
    notifier.state = opening ? sessionExercise.id : null;
    if (!opening || currentSets.isNotEmpty || targets == null) return;

    final db = ref.read(appDatabaseProvider);
    final previousSets = await getPreviousSetsForExercise(
      db,
      exerciseId: sessionExercise.exerciseId,
      excludeSessionId: sessionId,
    );
    final suggestion = previousSets.isEmpty
        ? null
        : suggestNextLoad(
            previousSets: previousSets,
            targetRepsMin: targets!.repsMin,
            targetRepsMax: targets!.repsMax,
          );

    final dao = ref.read(sessionLoggingDaoProvider);
    for (var i = 0; i < targets!.sets; i++) {
      final matchingPrevious = i < previousSets.length ? previousSets[i] : null;
      await dao.addSet(WorkoutSetsCompanion.insert(
        sessionExerciseId: sessionExercise.id,
        setNumber: i + 1,
        weightKg: Value(matchingPrevious?.weightKg ?? suggestion?.suggestedWeight),
        reps: Value(matchingPrevious?.reps ?? targets!.repsMax),
        isCompleted: const Value(false),
      ));
    }
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
    final Widget icon;
    switch (status) {
      case SessionExerciseStatus.pending:
        icon = const Icon(Icons.crop_square, size: 20, color: AppTheme.statusEmpty);
      case SessionExerciseStatus.inProgress:
        icon = const Icon(Icons.circle, size: 12, color: AppTheme.statusPlanned);
      case SessionExerciseStatus.completed:
        icon = const Icon(Icons.check_circle, size: 20, color: AppTheme.statusCompleted);
      case SessionExerciseStatus.skipped:
        icon = const Icon(Icons.remove_circle, size: 20, color: AppTheme.statusSkipped);
    }
    return AnimatedSwitcher(
      duration: AppMotion.fast,
      switchInCurve: AppMotion.curve,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
      child: KeyedSubtree(key: ValueKey(status), child: icon),
    );
  }
}

// Everything that used to live in the standalone ExerciseLoggingScreen,
// now rendered inline when a checklist row is expanded: last time, load
// suggestion, the set table, and the overflow menu — no navigation away
// from the checklist.
class _ExpandedExerciseDetail extends ConsumerWidget {
  const _ExpandedExerciseDetail({
    required this.sessionId,
    required this.sessionExercise,
    required this.exerciseName,
    required this.targets,
    required this.sets,
  });

  final int sessionId;
  final SessionExercise sessionExercise;
  final String exerciseName;
  final _ExerciseTargets? targets;
  final List<WorkoutSet> sets;

  int get exerciseId => sessionExercise.exerciseId;
  int get restSeconds => targets?.restSeconds ?? 90;
  int get repsMin => targets?.repsMin ?? 8;
  int get repsMax => targets?.repsMax ?? 12;
  int? get targetSets => targets?.sets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final previousSetsAsync = ref.watch(
      previousSetsProvider((exerciseId: exerciseId, excludeSessionId: sessionId)),
    );
    final previousSets = previousSetsAsync.valueOrNull ?? const <WorkoutSet>[];
    final suggestion = previousSets.isEmpty
        ? null
        : suggestNextLoad(previousSets: previousSets, targetRepsMin: repsMin, targetRepsMax: repsMax);

    final incompleteSets = sets.where((s) => !s.isCompleted);
    final activeSet = incompleteSets.isEmpty ? null : incompleteSets.first;
    final otherSets = [for (final s in sets) if (s.id != activeSet?.id) s];

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: AppSpacing.lg),
          if (previousSets.isNotEmpty || suggestion != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (previousSets.isNotEmpty)
                          Text(
                            'Última vez: ${previousSets.map((s) => '${_fmt(s.weightKg)}×${s.reps ?? '—'}').join(', ')}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        if (suggestion != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              suggestion.message,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _OverflowMenu(onSelected: (action) => _handleMenuAction(context, ref, action)),
                ],
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: _OverflowMenu(onSelected: (action) => _handleMenuAction(context, ref, action)),
            ),
          if (activeSet != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ActiveSetCard(
                key: ValueKey('active-${activeSet.id}'),
                set: activeSet,
                onComplete: (weight, reps) => _completeSet(context, ref, activeSet, weight: weight, reps: reps),
              ),
            ),
          for (final set in otherSets)
            _CompactSetRow(
              key: ValueKey('row-${set.id}'),
              set: set,
              onDelete: () => ref.read(sessionLoggingDaoProvider).deleteSet(set.id),
            ),
          if (otherSets.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addSet(ref, sets, suggestion),
              icon: const Icon(Icons.add),
              label: const Text('Añadir otra serie'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _changeExercise(context, ref),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Cambiar por otro'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _delete(context, ref),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Quitar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addSet(WidgetRef ref, List<WorkoutSet> existingSets, LoadSuggestion? suggestion) async {
    final last = existingSets.isEmpty ? null : existingSets.last;
    await ref.read(sessionLoggingDaoProvider).addSet(WorkoutSetsCompanion.insert(
          sessionExerciseId: sessionExercise.id,
          setNumber: existingSets.length + 1,
          weightKg: Value(last?.weightKg ?? suggestion?.suggestedWeight),
          reps: Value(last?.reps),
          isCompleted: const Value(false),
        ));
  }

  Future<void> _completeSet(
    BuildContext context,
    WidgetRef ref,
    WorkoutSet set, {
    required double? weight,
    required int? reps,
  }) async {
    final setId = set.id;
    await ref.read(sessionLoggingDaoProvider).updateSet(set.copyWith(
          weightKg: Value(weight),
          reps: Value(reps),
          isCompleted: true,
          completedAt: Value(DateTime.now()),
        ));

    HapticFeedback.lightImpact();
    ref.read(restTimerControllerProvider.notifier).start(restSeconds);
    await _syncExerciseStatus(ref);

    if (weight != null && reps != null) {
      final achieved = await checkAndRecordPRs(
        ref.read(appDatabaseProvider),
        exerciseId: exerciseId,
        setId: setId,
        weightKg: weight,
        reps: reps,
      );
      if (achieved.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('🏆 ¡Nuevo récord personal!')));
      }
    }
  }

  Future<void> _syncExerciseStatus(WidgetRef ref) async {
    final currentSets = ref.read(setsForExerciseProvider(sessionExercise.id)).valueOrNull ?? const [];
    final completedCount = currentSets.where((s) => s.isCompleted).length;
    final current = ref.read(sessionExerciseByIdProvider(sessionExercise.id)).valueOrNull;
    if (current == null || current.status == SessionExerciseStatus.skipped) return;

    final next = targetSets != null && completedCount >= targetSets!
        ? SessionExerciseStatus.completed
        : completedCount > 0
            ? SessionExerciseStatus.inProgress
            : SessionExerciseStatus.pending;
    if (next != current.status) {
      await ref.read(sessionLoggingDaoProvider).updateSessionExerciseStatus(sessionExercise.id, next);
    }

    if (next == SessionExerciseStatus.completed) {
      final expandedNotifier = ref.read(expandedSessionExerciseIdProvider.notifier);
      if (expandedNotifier.state == sessionExercise.id) {
        expandedNotifier.state = null;
      }
    }
  }

  Future<void> _handleMenuAction(BuildContext context, WidgetRef ref, _ExerciseMenuAction action) async {
    switch (action) {
      case _ExerciseMenuAction.history:
        await _showHistory(context, ref);
      case _ExerciseMenuAction.notes:
        await _editNotes(context, ref);
      case _ExerciseMenuAction.skip:
        await ref
            .read(sessionLoggingDaoProvider)
            .updateSessionExerciseStatus(sessionExercise.id, SessionExerciseStatus.skipped);
        ref.read(expandedSessionExerciseIdProvider.notifier).state = null;
    }
  }

  Future<void> _changeExercise(BuildContext context, WidgetRef ref) async {
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen(pickerMode: true)),
    );
    if (exercise == null) return;
    await ref
        .read(sessionLoggingDaoProvider)
        .updateSessionExercise(sessionExercise.copyWith(exerciseId: exercise.id));
    ref.read(expandedSessionExerciseIdProvider.notifier).state = null;
  }

  Future<void> _showHistory(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final history = await db.progressDao.estimatedOneRepMaxHistory(exerciseId);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historial (1RM estimado)'),
        content: SizedBox(
          width: double.maxFinite,
          child: history.isEmpty
              ? const Text('Todavía no hay historial para este ejercicio.')
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final point in history.reversed)
                      ListTile(
                        dense: true,
                        title: Text('${point.value.toStringAsFixed(1)} kg'),
                        trailing: Text(DateFormat('d MMM', 'es').format(point.date)),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _editNotes(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: sessionExercise.notes ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notas'),
        content: TextField(controller: controller, maxLines: 4, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await ref
        .read(sessionLoggingDaoProvider)
        .updateSessionExercise(sessionExercise.copyWith(notes: Value(result.isEmpty ? null : result)));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ejercicio'),
        content: const Text('Se eliminará este ejercicio y sus series de este entrenamiento.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(sessionLoggingDaoProvider).removeSessionExercise(sessionExercise.id);
    ref.read(expandedSessionExerciseIdProvider.notifier).state = null;
  }

  String _fmt(double? value) {
    if (value == null) return '—';
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.onSelected});

  final ValueChanged<_ExerciseMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ExerciseMenuAction>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: _ExerciseMenuAction.history, child: Text('Historial')),
        PopupMenuItem(value: _ExerciseMenuAction.notes, child: Text('Notas')),
        PopupMenuItem(value: _ExerciseMenuAction.skip, child: Text('Omitir ejercicio')),
      ],
    );
  }
}

// The one set the user is currently meant to log, front and center with
// +/- steppers instead of raw text fields — matches "no abrir una ventana
// con teclado para poner los kilos".
class _ActiveSetCard extends ConsumerStatefulWidget {
  const _ActiveSetCard({super.key, required this.set, required this.onComplete});

  final WorkoutSet set;
  final Future<void> Function(double? weight, int? reps) onComplete;

  @override
  ConsumerState<_ActiveSetCard> createState() => _ActiveSetCardState();
}

class _ActiveSetCardState extends ConsumerState<_ActiveSetCard> {
  late double _weight;
  late int _reps;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _weight = widget.set.weightKg ?? 0;
    _reps = widget.set.reps ?? 0;
  }

  void _adjustWeight(double delta) => setState(() => _weight = (_weight + delta).clamp(0, 999));
  void _adjustReps(int delta) => setState(() => _reps = (_reps + delta).clamp(0, 99));

  Future<void> _markSet() async {
    setState(() => _submitting = true);
    await widget.onComplete(_weight, _reps);
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SERIE ${widget.set.setNumber}', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _Stepper(label: 'kg', value: _fmt(_weight), onDecrement: () => _adjustWeight(-2.5), onIncrement: () => _adjustWeight(2.5))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _Stepper(label: 'reps', value: '$_reps', onDecrement: () => _adjustReps(-1), onIncrement: () => _adjustReps(1))),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _markSet,
              icon: const Icon(Icons.check),
              label: const Text('Finalizar serie'),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final String value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StepperButton(icon: Icons.remove, onTap: onDecrement),
        Expanded(
          child: Column(
            children: [
              Text(value, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        _StepperButton(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

// A set that isn't the active one — either already completed, or queued
// further down the plan. Shown as a plain summary row with a way to remove it.
class _CompactSetRow extends StatelessWidget {
  const _CompactSetRow({super.key, required this.set, required this.onDelete});

  final WorkoutSet set;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            set.isCompleted ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: set.isCompleted ? AppTheme.statusCompleted : mutedColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Serie ${set.setNumber}',
              style: theme.textTheme.bodyMedium?.copyWith(color: set.isCompleted ? null : mutedColor),
            ),
          ),
          Text(
            '${_fmt(set.weightKg)} kg × ${set.reps ?? '—'}',
            style: theme.textTheme.bodyMedium?.copyWith(color: set.isCompleted ? null : mutedColor),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _fmt(double? value) {
    if (value == null) return '—';
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}
