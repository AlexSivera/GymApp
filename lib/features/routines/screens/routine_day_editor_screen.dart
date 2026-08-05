import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/exercise_thumbnail.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/workout_session/start_session.dart';
import '../../exercise_library/providers/exercise_library_providers.dart';
import '../../exercise_library/screens/exercise_library_screen.dart';
import '../providers/routines_providers.dart';

class RoutineDayEditorScreen extends ConsumerWidget {
  const RoutineDayEditorScreen({super.key, required this.routineDayId, required this.dayName});

  final int routineDayId;
  final String dayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exercisesAsync = ref.watch(dayExercisesProvider(routineDayId));
    final allExercises = ref.watch(allExercisesProvider).valueOrNull ?? const [];
    final exercisesById = {for (final e in allExercises) e.id: e};

    return Scaffold(
      appBar: AppBar(
        title: Text(dayName),
        actions: [
          if ((exercisesAsync.valueOrNull ?? const []).isNotEmpty)
            TextButton.icon(
              onPressed: () => _startWorkout(context, ref),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Empezar'),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExercise(context, ref),
        child: const Icon(Icons.add),
      ),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (routineExercises) {
          if (routineExercises.isEmpty) {
            return Center(
              child: Text(
                'Añade ejercicios a este día con el botón +.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routineExercises.length,
            onReorderItem: (oldIndex, newIndex) =>
                _reorder(ref, routineExercises, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final entry = routineExercises[index];
              final exercise = exercisesById[entry.exerciseId];
              return Padding(
                key: ValueKey(entry.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: _RoutineExerciseRow(
                  entry: entry,
                  exerciseName: exercise?.name ?? 'Ejercicio eliminado',
                  imagePaths: exercise?.imagePaths ?? const [],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _reorder(
    WidgetRef ref,
    List<RoutineExercise> current,
    int oldIndex,
    int newIndex,
  ) async {
    final list = [...current];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await ref.read(routinesDaoProvider).reorderExercises(list.map((e) => e.id).toList());
  }

  Future<void> _startWorkout(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final today = DateTime.now();
    final existing = await db.workoutSessionsDao.getSessionForDate(today);

    if (existing != null && existing.status == SessionStatus.planned) {
      await startPlannedSession(db, session: existing.copyWith(routineDayId: Value(routineDayId)));
    } else {
      await startSessionFromRoutineDay(db, routineDayId: routineDayId, date: today);
    }
    if (context.mounted) context.go('/workout');
  }

  // Multi-select the exercises, then drop straight back onto this screen —
  // each gets sane defaults (3×8-12, descanso 90s) and its row opens
  // expanded so the sets/reps/weight can be tweaked right away.
  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final exercises = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute(
        builder: (_) => const ExerciseLibraryScreen(pickerMode: true, multiSelect: true),
      ),
    );
    if (exercises == null || exercises.isEmpty) return;

    var orderIndex = ref.read(dayExercisesProvider(routineDayId)).valueOrNull?.length ?? 0;
    final addedIds = <int>{};
    for (final exercise in exercises) {
      final id = await ref.read(routinesDaoProvider).addExerciseToDay(RoutineExercisesCompanion.insert(
            routineDayId: routineDayId,
            exerciseId: exercise.id,
            orderIndex: orderIndex++,
            targetSets: 3,
            targetRepsMin: 8,
            targetRepsMax: 12,
            restSeconds: const Value(90),
          ));
      addedIds.add(id);
    }
    ref.read(expandedRoutineExerciseIdsProvider.notifier).state = addedIds;
  }
}

class _RoutineExerciseRow extends ConsumerWidget {
  const _RoutineExerciseRow({
    required this.entry,
    required this.exerciseName,
    required this.imagePaths,
  });

  final RoutineExercise entry;
  final String exerciseName;
  final List<String> imagePaths;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(expandedRoutineExerciseIdsProvider).contains(entry.id);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: ExerciseThumbnail(imagePaths: imagePaths),
            title: Text(exerciseName),
            subtitle: Text(_summarize(entry)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => ref.read(routinesDaoProvider).removeExerciseFromDay(entry.id),
            ),
            onTap: () {
              final notifier = ref.read(expandedRoutineExerciseIdsProvider.notifier);
              final current = notifier.state;
              notifier.state = current.contains(entry.id)
                  ? ({...current}..remove(entry.id))
                  : ({...current, entry.id});
            },
          ),
          AnimatedSize(
            duration: AppMotion.normal,
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? _RoutineExerciseFields(key: ValueKey('fields-${entry.id}'), entry: entry)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  String _summarize(RoutineExercise entry) {
    final parts = <String>[
      '${entry.targetSets} series',
      '${entry.targetRepsMin}-${entry.targetRepsMax} reps',
      if (entry.targetWeight != null) '${_fmt(entry.targetWeight!)} kg',
      if (entry.restSeconds != null) 'descanso ${entry.restSeconds}s',
    ];
    return parts.join(' · ');
  }

  String _fmt(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

class _RoutineExerciseFields extends ConsumerStatefulWidget {
  const _RoutineExerciseFields({super.key, required this.entry});

  final RoutineExercise entry;

  @override
  ConsumerState<_RoutineExerciseFields> createState() => _RoutineExerciseFieldsState();
}

const _restPresets = [60, 90, 120, 180];

class _RoutineExerciseFieldsState extends ConsumerState<_RoutineExerciseFields> {
  late final TextEditingController _sets;
  late final TextEditingController _repsMin;
  late final TextEditingController _repsMax;
  late final TextEditingController _weight;
  late int? _restSeconds;

  @override
  void initState() {
    super.initState();
    _sets = TextEditingController(text: '${widget.entry.targetSets}');
    _repsMin = TextEditingController(text: '${widget.entry.targetRepsMin}');
    _repsMax = TextEditingController(text: '${widget.entry.targetRepsMax}');
    _weight = TextEditingController(text: widget.entry.targetWeight?.toString() ?? '');
    _restSeconds = widget.entry.restSeconds;
  }

  @override
  void dispose() {
    _sets.dispose();
    _repsMin.dispose();
    _repsMax.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _persist() async {
    await ref.read(routinesDaoProvider).updateRoutineExercise(widget.entry.copyWith(
          targetSets: int.tryParse(_sets.text) ?? widget.entry.targetSets,
          targetRepsMin: int.tryParse(_repsMin.text) ?? widget.entry.targetRepsMin,
          targetRepsMax: int.tryParse(_repsMax.text) ?? widget.entry.targetRepsMax,
          targetWeight: Value(double.tryParse(_weight.text.replaceAll(',', '.'))),
          restSeconds: Value(_restSeconds),
        ));
  }

  Future<void> _selectRest(int seconds) async {
    setState(() => _restSeconds = seconds);
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restOptions = [
      ..._restPresets,
      if (_restSeconds != null && !_restPresets.contains(_restSeconds)) _restSeconds!,
    ]..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _statField(_sets, 'Series')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _statField(_repsMin, 'Reps mín.')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _statField(_repsMax, 'Reps máx.')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _statField(_weight, 'Peso (kg)', decimal: true)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Descanso',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final seconds in restOptions)
                _RestChip(
                  label: '${seconds}s',
                  selected: seconds == _restSeconds,
                  onTap: () => _selectRest(seconds),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statField(TextEditingController controller, String label, {bool decimal = false}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            style: theme.textTheme.titleLarge,
            decoration: InputDecoration(
              hintText: '—',
              hintStyle: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onEditingComplete: _persist,
            onTapOutside: (_) => _persist(),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _RestChip extends StatelessWidget {
  const _RestChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
