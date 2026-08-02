import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/workout_session/start_session.dart';
import '../../exercise_library/providers/exercise_library_providers.dart';
import '../../exercise_library/screens/exercise_library_screen.dart';
import '../../workout_session/screens/workout_session_screen.dart';
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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routineExercises.length,
            itemBuilder: (context, index) {
              final entry = routineExercises[index];
              final exercise = exercisesById[entry.exerciseId];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    title: Text(exercise?.name ?? 'Ejercicio eliminado'),
                    subtitle: Text(_summarize(entry)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          ref.read(routinesDaoProvider).removeExerciseFromDay(entry.id),
                    ),
                    onTap: () => _editExercise(context, ref, entry),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _summarize(RoutineExercise entry) {
    final parts = <String>[
      '${entry.targetSets} series',
      '${entry.targetRepsMin}-${entry.targetRepsMax} reps',
      if (entry.targetRir != null) 'RIR ${entry.targetRir}',
      if (entry.restSeconds != null) 'descanso ${entry.restSeconds}s',
    ];
    return parts.join(' · ');
  }

  Future<void> _startWorkout(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final sessionId = await startSessionFromRoutineDay(
      db,
      routineDayId: routineDayId,
      date: DateTime.now(),
    );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkoutSessionScreen(sessionId: sessionId)),
    );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen(pickerMode: true)),
    );
    if (exercise == null || !context.mounted) return;

    final config = await _showConfigDialog(context);
    if (config == null) return;

    final currentCount = ref.read(dayExercisesProvider(routineDayId)).valueOrNull?.length ?? 0;
    await ref.read(routinesDaoProvider).addExerciseToDay(RoutineExercisesCompanion.insert(
          routineDayId: routineDayId,
          exerciseId: exercise.id,
          orderIndex: currentCount,
          targetSets: config.sets,
          targetRepsMin: config.repsMin,
          targetRepsMax: config.repsMax,
          targetRir: Value(config.rir),
          restSeconds: Value(config.restSeconds),
        ));
  }

  Future<void> _editExercise(BuildContext context, WidgetRef ref, RoutineExercise entry) async {
    final config = await _showConfigDialog(
      context,
      initialSets: entry.targetSets,
      initialRepsMin: entry.targetRepsMin,
      initialRepsMax: entry.targetRepsMax,
      initialRir: entry.targetRir,
      initialRest: entry.restSeconds,
    );
    if (config == null) return;

    await ref.read(routinesDaoProvider).updateRoutineExercise(entry.copyWith(
          targetSets: config.sets,
          targetRepsMin: config.repsMin,
          targetRepsMax: config.repsMax,
          targetRir: Value(config.rir),
          restSeconds: Value(config.restSeconds),
        ));
  }

  Future<_ExerciseConfig?> _showConfigDialog(
    BuildContext context, {
    int initialSets = 3,
    int initialRepsMin = 8,
    int initialRepsMax = 12,
    int? initialRir,
    int? initialRest = 90,
  }) {
    return showDialog<_ExerciseConfig>(
      context: context,
      builder: (context) => _ExerciseConfigDialog(
        initialSets: initialSets,
        initialRepsMin: initialRepsMin,
        initialRepsMax: initialRepsMax,
        initialRir: initialRir,
        initialRest: initialRest,
      ),
    );
  }
}

class _ExerciseConfig {
  const _ExerciseConfig({
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    required this.rir,
    required this.restSeconds,
  });

  final int sets;
  final int repsMin;
  final int repsMax;
  final int? rir;
  final int? restSeconds;
}

class _ExerciseConfigDialog extends StatefulWidget {
  const _ExerciseConfigDialog({
    required this.initialSets,
    required this.initialRepsMin,
    required this.initialRepsMax,
    required this.initialRir,
    required this.initialRest,
  });

  final int initialSets;
  final int initialRepsMin;
  final int initialRepsMax;
  final int? initialRir;
  final int? initialRest;

  @override
  State<_ExerciseConfigDialog> createState() => _ExerciseConfigDialogState();
}

class _ExerciseConfigDialogState extends State<_ExerciseConfigDialog> {
  late final TextEditingController _sets;
  late final TextEditingController _repsMin;
  late final TextEditingController _repsMax;
  late final TextEditingController _rir;
  late final TextEditingController _rest;

  @override
  void initState() {
    super.initState();
    _sets = TextEditingController(text: '${widget.initialSets}');
    _repsMin = TextEditingController(text: '${widget.initialRepsMin}');
    _repsMax = TextEditingController(text: '${widget.initialRepsMax}');
    _rir = TextEditingController(text: widget.initialRir?.toString() ?? '');
    _rest = TextEditingController(text: widget.initialRest?.toString() ?? '');
  }

  @override
  void dispose() {
    _sets.dispose();
    _repsMin.dispose();
    _repsMax.dispose();
    _rir.dispose();
    _rest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar ejercicio'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _numberField(_sets, 'Series'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _numberField(_repsMin, 'Reps mín.')),
              const SizedBox(width: 12),
              Expanded(child: _numberField(_repsMax, 'Reps máx.')),
            ],
          ),
          const SizedBox(height: 12),
          _numberField(_rir, 'RIR (opcional)'),
          const SizedBox(height: 12),
          _numberField(_rest, 'Descanso en segundos (opcional)'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(
          onPressed: () {
            final sets = int.tryParse(_sets.text) ?? widget.initialSets;
            final repsMin = int.tryParse(_repsMin.text) ?? widget.initialRepsMin;
            final repsMax = int.tryParse(_repsMax.text) ?? widget.initialRepsMax;
            final rir = int.tryParse(_rir.text);
            final rest = int.tryParse(_rest.text);
            Navigator.of(context).pop(_ExerciseConfig(
              sets: sets,
              repsMin: repsMin,
              repsMax: repsMax,
              rir: rir,
              restSeconds: rest,
            ));
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}
