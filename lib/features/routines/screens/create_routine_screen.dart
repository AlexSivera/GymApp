import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/exercise_thumbnail.dart';
import '../../../data/database/app_database.dart';
import '../../exercise_library/screens/exercise_library_screen.dart';
import '../providers/routines_providers.dart';
import '../widgets/exercise_config_fields.dart';

// A local, not-yet-persisted exercise entry — edited freely in memory while
// building the routine, only written to the DB once "Guardar" is tapped.
class _StagedExercise {
  _StagedExercise({required this.localId, required this.exerciseId, required this.name, required this.imagePaths});

  final int localId;
  final int exerciseId;
  final String name;
  final List<String> imagePaths;
  int sets = 3;
  int repsMin = 8;
  int repsMax = 12;
  double? weight;
  int? restSeconds = 90;
}

// Full-screen "create routine" flow — no name dialog: the title is an
// inline field at the top, and exercises are staged locally (with the same
// series/reps/peso/descanso editors as the day editor) until "Guardar"
// creates the Routine, its first Día, and every RoutineExercise in one go.
class CreateRoutineScreen extends ConsumerStatefulWidget {
  const CreateRoutineScreen({super.key});

  @override
  ConsumerState<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends ConsumerState<CreateRoutineScreen> {
  final _titleController = TextEditingController();
  final _exercises = <_StagedExercise>[];
  int? _expandedLocalId;
  int _nextLocalId = 0;
  bool _titleHasText = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      final hasText = _titleController.text.trim().isNotEmpty;
      if (hasText != _titleHasText) setState(() => _titleHasText = hasText);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addExercises() async {
    final picked = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen(pickerMode: true, multiSelect: true)),
    );
    if (picked == null || picked.isEmpty) return;
    setState(() {
      for (final exercise in picked) {
        final id = _nextLocalId++;
        _exercises.add(_StagedExercise(
          localId: id,
          exerciseId: exercise.id,
          name: exercise.name,
          imagePaths: exercise.imagePaths,
        ));
        _expandedLocalId = id;
      }
    });
  }

  void _removeExercise(_StagedExercise exercise) {
    setState(() => _exercises.remove(exercise));
  }

  Future<void> _cancel() async {
    final hasContent = _titleController.text.trim().isNotEmpty || _exercises.isNotEmpty;
    if (hasContent) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Descartar rutina?'),
          content: const Text('Perderás el título y los ejercicios que has añadido.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false), child: const Text('Seguir editando')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Descartar')),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);

    final dao = ref.read(routinesDaoProvider);
    final routineId = await dao.createRoutine(RoutinesCompanion.insert(name: title));
    final dayId = await dao.createDay(
      RoutineDaysCompanion.insert(routineId: routineId, name: 'Día 1', dayOrder: 0),
    );
    for (var i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i];
      await dao.addExerciseToDay(RoutineExercisesCompanion.insert(
        routineDayId: dayId,
        exerciseId: exercise.exerciseId,
        orderIndex: i,
        targetSets: exercise.sets,
        targetRepsMin: exercise.repsMin,
        targetRepsMax: exercise.repsMax,
        targetWeight: Value(exercise.weight),
        restSeconds: Value(exercise.restSeconds),
      ));
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(onPressed: _saving ? null : _cancel, child: const Text('Cancelar')),
        leadingWidth: 100,
        title: const Text('Crear Rutina'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: _saving || !_titleHasText ? null : _save,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar'),
            ),
          ),
        ],
      ),
      floatingActionButton: _exercises.isEmpty
          ? null
          : FloatingActionButton(onPressed: _addExercises, child: const Icon(Icons.add)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.titleLarge,
            decoration: const InputDecoration(hintText: 'Título de la rutina'),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxxl),
              child: Column(
                children: [
                  Icon(Icons.fitness_center, size: 40, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Empieza agregando un ejercicio a tu rutina',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addExercises,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar ejercicio'),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final exercise in _exercises) ...[
              _StagedExerciseCard(
                key: ValueKey(exercise.localId),
                exercise: exercise,
                isExpanded: _expandedLocalId == exercise.localId,
                onToggleExpand: () => setState(() =>
                    _expandedLocalId = _expandedLocalId == exercise.localId ? null : exercise.localId),
                onChanged: () => setState(() {}),
                onRemove: () => _removeExercise(exercise),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _StagedExerciseCard extends StatefulWidget {
  const _StagedExerciseCard({
    super.key,
    required this.exercise,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onChanged,
    required this.onRemove,
  });

  final _StagedExercise exercise;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_StagedExerciseCard> createState() => _StagedExerciseCardState();
}

class _StagedExerciseCardState extends State<_StagedExerciseCard> {
  late final _sets = TextEditingController(text: '${widget.exercise.sets}');
  late final _repsMin = TextEditingController(text: '${widget.exercise.repsMin}');
  late final _repsMax = TextEditingController(text: '${widget.exercise.repsMax}');
  late final _weight = TextEditingController(text: widget.exercise.weight?.toString() ?? '');

  @override
  void dispose() {
    _sets.dispose();
    _repsMin.dispose();
    _repsMax.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: ExerciseThumbnail(imagePaths: widget.exercise.imagePaths),
            title: Text(widget.exercise.name),
            subtitle: Text(_summary()),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: widget.onRemove,
            ),
            onTap: widget.onToggleExpand,
          ),
          AnimatedSize(
            duration: AppMotion.normal,
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: widget.isExpanded ? _fields(theme) : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _fields(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: StatNumberField(
                  controller: _sets,
                  label: 'Series',
                  onChanged: (v) => widget.exercise.sets = int.tryParse(v) ?? widget.exercise.sets,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatNumberField(
                  controller: _repsMin,
                  label: 'Reps mín.',
                  onChanged: (v) => widget.exercise.repsMin = int.tryParse(v) ?? widget.exercise.repsMin,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatNumberField(
                  controller: _repsMax,
                  label: 'Reps máx.',
                  onChanged: (v) => widget.exercise.repsMax = int.tryParse(v) ?? widget.exercise.repsMax,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatNumberField(
                  controller: _weight,
                  label: 'Peso (kg)',
                  decimal: true,
                  onChanged: (v) => widget.exercise.weight = double.tryParse(v.replaceAll(',', '.')),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Descanso',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xs),
          RestSecondsChipsRow(
            selected: widget.exercise.restSeconds,
            onSelected: (seconds) {
              widget.exercise.restSeconds = seconds;
              widget.onChanged();
            },
          ),
        ],
      ),
    );
  }

  String _summary() {
    final e = widget.exercise;
    final parts = <String>[
      '${e.sets} series',
      '${e.repsMin}-${e.repsMax} reps',
      if (e.weight != null) '${_fmt(e.weight!)} kg',
      if (e.restSeconds != null) 'descanso ${e.restSeconds}s',
    ];
    return parts.join(' · ');
  }

  String _fmt(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}
