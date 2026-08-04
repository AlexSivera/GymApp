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
enum _ExerciseMenuAction { changeExercise, history, notes, skip, delete }

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
    final isExpanded = ref.watch(expandedSessionExerciseIdProvider) == sessionExercise.id;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
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
            onTap: () => _toggleExpanded(ref),
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

  void _toggleExpanded(WidgetRef ref) {
    final notifier = ref.read(expandedSessionExerciseIdProvider.notifier);
    notifier.state = notifier.state == sessionExercise.id ? null : sessionExercise.id;
  }

  Future<void> _toggleDone(WidgetRef ref, bool checked) async {
    await ref.read(sessionLoggingDaoProvider).updateSessionExerciseStatus(
          sessionExercise.id,
          checked ? SessionExerciseStatus.completed : SessionExerciseStatus.pending,
        );
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PopupMenuButton<_ExerciseMenuAction>(
                onSelected: (action) => _handleMenuAction(context, ref, action),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: _ExerciseMenuAction.changeExercise, child: Text('Cambiar ejercicio')),
                  PopupMenuItem(value: _ExerciseMenuAction.history, child: Text('Historial')),
                  PopupMenuItem(value: _ExerciseMenuAction.notes, child: Text('Notas')),
                  PopupMenuItem(value: _ExerciseMenuAction.skip, child: Text('Omitir ejercicio')),
                  PopupMenuItem(value: _ExerciseMenuAction.delete, child: Text('Eliminar ejercicio')),
                ],
              ),
            ],
          ),
          if (previousSets.isNotEmpty) ...[
            Text('Última vez', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final s in previousSets) Chip(label: Text('${_fmt(s.weightKg)} × ${s.reps ?? '—'}')),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (suggestion != null) ...[
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(suggestion.message, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (sets.isNotEmpty) ...[
            Row(
              children: [
                SizedBox(width: 32, child: Text('Serie', style: theme.textTheme.labelMedium)),
                Expanded(child: Text('Peso', style: theme.textTheme.labelMedium)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Reps', style: theme.textTheme.labelMedium)),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final set in sets)
              Dismissible(
                key: ValueKey(set.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                ),
                onDismissed: (_) => ref.read(sessionLoggingDaoProvider).deleteSet(set.id),
                child: _SetRow(
                  key: ValueKey('row-${set.id}'),
                  set: set,
                  onComplete: (set, {required weight, required reps}) =>
                      _completeSet(context, ref, set, weight: weight, reps: reps),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addSet(ref, sets, suggestion),
              icon: const Icon(Icons.add),
              label: const Text('Añadir serie'),
            ),
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
  }

  Future<void> _handleMenuAction(BuildContext context, WidgetRef ref, _ExerciseMenuAction action) async {
    switch (action) {
      case _ExerciseMenuAction.changeExercise:
        await _changeExercise(context, ref);
      case _ExerciseMenuAction.history:
        await _showHistory(context, ref);
      case _ExerciseMenuAction.notes:
        await _editNotes(context, ref);
      case _ExerciseMenuAction.skip:
        await ref
            .read(sessionLoggingDaoProvider)
            .updateSessionExerciseStatus(sessionExercise.id, SessionExerciseStatus.skipped);
        ref.read(expandedSessionExerciseIdProvider.notifier).state = null;
      case _ExerciseMenuAction.delete:
        await _delete(context, ref);
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

class _SetRow extends ConsumerStatefulWidget {
  const _SetRow({super.key, required this.set, required this.onComplete});

  final WorkoutSet set;
  final Future<void> Function(WorkoutSet set, {required double? weight, required int? reps}) onComplete;

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.set.weightKg?.toString() ?? '');
    _repsController = TextEditingController(text: widget.set.reps?.toString() ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  double? get _weight => double.tryParse(_weightController.text.replaceAll(',', '.'));
  int? get _reps => int.tryParse(_repsController.text);

  Future<void> _persistFieldEdit() async {
    if (!widget.set.isCompleted) return; // Uncompleted rows persist on complete instead.
    await ref
        .read(sessionLoggingDaoProvider)
        .updateSet(widget.set.copyWith(weightKg: Value(_weight), reps: Value(_reps)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = widget.set.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('${widget.set.setNumber}', style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            child: TextField(
              controller: _weightController,
              enabled: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(isDense: true, hintText: 'kg'),
              onEditingComplete: _persistFieldEdit,
              onTapOutside: (_) => _persistFieldEdit(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(isDense: true, hintText: 'reps'),
              onEditingComplete: _persistFieldEdit,
              onTapOutside: (_) => _persistFieldEdit(),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: AppMotion.fast,
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: Icon(
                  isDone ? Icons.check_circle : Icons.check_circle_outline,
                  key: ValueKey(isDone),
                  color: isDone ? AppTheme.statusCompleted : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onPressed: isDone ? null : () => widget.onComplete(widget.set, weight: _weight, reps: _reps),
            ),
          ),
        ],
      ),
    );
  }
}
