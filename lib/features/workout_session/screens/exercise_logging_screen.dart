import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/progression_engine/check_and_record_prs.dart';
import '../../../services/progression_engine/previous_performance.dart';
import '../../../services/progression_engine/suggest_next_load.dart';
import '../../exercise_library/screens/exercise_library_screen.dart';
import '../providers/rest_timer_controller.dart';
import '../providers/workout_session_providers.dart';
import '../widgets/rest_timer_banner.dart';

class ExerciseLoggingScreen extends ConsumerStatefulWidget {
  const ExerciseLoggingScreen({
    super.key,
    required this.sessionExerciseId,
    required this.exerciseId,
    required this.sessionId,
    required this.exerciseName,
    this.restSeconds = 90,
    this.targetRepsMin = 8,
    this.targetRepsMax = 12,
    this.targetSets,
  });

  final int sessionExerciseId;
  final int exerciseId;
  final int sessionId;
  final String exerciseName;
  final int restSeconds;
  final int targetRepsMin;
  final int targetRepsMax;
  final int? targetSets;

  @override
  ConsumerState<ExerciseLoggingScreen> createState() => _ExerciseLoggingScreenState();
}

class _ExerciseLoggingScreenState extends ConsumerState<ExerciseLoggingScreen> {
  LoadSuggestion? _suggestion;
  List<WorkoutSet> _previousSets = const [];

  @override
  void initState() {
    super.initState();
    _loadSuggestion();
  }

  Future<void> _loadSuggestion() async {
    final db = ref.read(appDatabaseProvider);
    final previousSets = await getPreviousSetsForExercise(
      db,
      exerciseId: widget.exerciseId,
      excludeSessionId: widget.sessionId,
    );
    if (!mounted) return;
    setState(() {
      _previousSets = previousSets;
      _suggestion = suggestNextLoad(
        previousSets: previousSets,
        targetRepsMin: widget.targetRepsMin,
        targetRepsMax: widget.targetRepsMax,
      );
    });
  }

  Future<void> _addSet(List<WorkoutSet> existingSets) async {
    final last = existingSets.isEmpty ? null : existingSets.last;
    await ref.read(sessionLoggingDaoProvider).addSet(WorkoutSetsCompanion.insert(
          sessionExerciseId: widget.sessionExerciseId,
          setNumber: existingSets.length + 1,
          weightKg: Value(last?.weightKg ?? _suggestion?.suggestedWeight),
          reps: Value(last?.reps),
          isCompleted: const Value(false),
        ));
  }

  Future<void> _completeSet(WorkoutSet set, {required double? weight, required int? reps}) async {
    final setId = set.id;
    await ref.read(sessionLoggingDaoProvider).updateSet(set.copyWith(
          weightKg: Value(weight),
          reps: Value(reps),
          isCompleted: true,
          completedAt: Value(DateTime.now()),
        ));

    HapticFeedback.lightImpact();
    ref.read(restTimerControllerProvider.notifier).start(widget.restSeconds);
    await _syncExerciseStatus();

    if (weight != null && reps != null) {
      final achieved = await checkAndRecordPRs(
        ref.read(appDatabaseProvider),
        exerciseId: widget.exerciseId,
        setId: setId,
        weightKg: weight,
        reps: reps,
      );
      if (achieved.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('🏆 ¡Nuevo récord personal!')));
      }
    }
  }

  Future<void> _syncExerciseStatus() async {
    final sets = ref.read(setsForExerciseProvider(widget.sessionExerciseId)).valueOrNull ?? const [];
    final completedCount = sets.where((s) => s.isCompleted).length;
    final current = ref.read(sessionExerciseByIdProvider(widget.sessionExerciseId)).valueOrNull;
    if (current == null || current.status == SessionExerciseStatus.skipped) return;

    final next = widget.targetSets != null && completedCount >= widget.targetSets!
        ? SessionExerciseStatus.completed
        : completedCount > 0
            ? SessionExerciseStatus.inProgress
            : SessionExerciseStatus.pending;
    if (next != current.status) {
      await ref.read(sessionLoggingDaoProvider).updateSessionExerciseStatus(widget.sessionExerciseId, next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final setsAsync = ref.watch(setsForExerciseProvider(widget.sessionExerciseId));
    final sets = setsAsync.valueOrNull ?? const <WorkoutSet>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        actions: [
          PopupMenuButton<_ExerciseMenuAction>(
            onSelected: (action) => _handleMenuAction(context, action),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSet(sets),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const RestTimerBanner(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (_previousSets.isNotEmpty) ...[
            Text('Última vez', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final s in _previousSets)
                  Chip(label: Text('${_fmt(s.weightKg)} × ${s.reps ?? '—'}')),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (_suggestion != null) ...[
            AppCard(
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(_suggestion!.message, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (sets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(
                child: Text(
                  'Añade la primera serie con el botón +.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else ...[
            Row(
              children: [
                SizedBox(width: 40, child: Text('Serie', style: theme.textTheme.labelMedium)),
                Expanded(child: Text('Peso', style: theme.textTheme.labelMedium)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Reps', style: theme.textTheme.labelMedium)),
                const SizedBox(width: 48),
              ],
            ),
            const Divider(height: AppSpacing.lg),
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
                child: _SetRow(key: ValueKey('row-${set.id}'), set: set, onComplete: _completeSet),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(BuildContext context, _ExerciseMenuAction action) async {
    switch (action) {
      case _ExerciseMenuAction.changeExercise:
        await _changeExercise(context);
      case _ExerciseMenuAction.history:
        await _showHistory(context);
      case _ExerciseMenuAction.notes:
        await _editNotes(context);
      case _ExerciseMenuAction.skip:
        await ref
            .read(sessionLoggingDaoProvider)
            .updateSessionExerciseStatus(widget.sessionExerciseId, SessionExerciseStatus.skipped);
        if (context.mounted) Navigator.of(context).pop();
      case _ExerciseMenuAction.delete:
        await _delete(context);
    }
  }

  Future<void> _changeExercise(BuildContext context) async {
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen(pickerMode: true)),
    );
    if (exercise == null) return;
    final current = ref.read(sessionExerciseByIdProvider(widget.sessionExerciseId)).valueOrNull;
    if (current == null) return;
    await ref.read(sessionLoggingDaoProvider).updateSessionExercise(
          current.copyWith(exerciseId: exercise.id),
        );
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _showHistory(BuildContext context) async {
    final db = ref.read(appDatabaseProvider);
    final history = await db.progressDao.estimatedOneRepMaxHistory(widget.exerciseId);
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

  Future<void> _editNotes(BuildContext context) async {
    final current = ref.read(sessionExerciseByIdProvider(widget.sessionExerciseId)).valueOrNull;
    final controller = TextEditingController(text: current?.notes ?? '');
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
    if (result == null || current == null) return;
    await ref
        .read(sessionLoggingDaoProvider)
        .updateSessionExercise(current.copyWith(notes: Value(result.isEmpty ? null : result)));
  }

  Future<void> _delete(BuildContext context) async {
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
    await ref.read(sessionLoggingDaoProvider).removeSessionExercise(widget.sessionExerciseId);
    if (context.mounted) Navigator.of(context).pop();
  }

  String _fmt(double? value) {
    if (value == null) return '—';
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}

enum _ExerciseMenuAction { changeExercise, history, notes, skip, delete }

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
            width: 40,
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
              icon: Icon(
                isDone ? Icons.check_circle : Icons.check_circle_outline,
                color: isDone ? AppTheme.statusCompleted : theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: isDone ? null : () => widget.onComplete(widget.set, weight: _weight, reps: _reps),
            ),
          ),
        ],
      ),
    );
  }
}
