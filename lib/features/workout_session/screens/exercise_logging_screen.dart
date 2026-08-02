import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../providers/workout_session_providers.dart';
import '../widgets/rest_timer_banner.dart';

class ExerciseLoggingScreen extends ConsumerStatefulWidget {
  const ExerciseLoggingScreen({
    super.key,
    required this.sessionExerciseId,
    required this.exerciseName,
    this.restSeconds = 90,
  });

  final int sessionExerciseId;
  final String exerciseName;
  final int restSeconds;

  @override
  ConsumerState<ExerciseLoggingScreen> createState() => _ExerciseLoggingScreenState();
}

class _ExerciseLoggingScreenState extends ConsumerState<ExerciseLoggingScreen> {
  int _restNonce = 0;
  bool _showRestTimer = false;

  Future<void> _addSet(List<WorkoutSet> existingSets) async {
    final last = existingSets.isEmpty ? null : existingSets.last;
    final config = await _showSetDialog(
      initialWeight: last?.weightKg,
      initialReps: last?.reps,
    );
    if (config == null) return;

    await ref.read(sessionLoggingDaoProvider).addSet(WorkoutSetsCompanion.insert(
          sessionExerciseId: widget.sessionExerciseId,
          setNumber: existingSets.length + 1,
          weightKg: Value(config.weight),
          reps: Value(config.reps),
          isCompleted: const Value(true),
          completedAt: Value(DateTime.now()),
        ));

    setState(() {
      _restNonce++;
      _showRestTimer = true;
    });
  }

  Future<void> _editSet(WorkoutSet set) async {
    final config = await _showSetDialog(initialWeight: set.weightKg, initialReps: set.reps);
    if (config == null) return;
    await ref.read(sessionLoggingDaoProvider).updateSet(
          set.copyWith(weightKg: Value(config.weight), reps: Value(config.reps)),
        );
  }

  Future<_SetInput?> _showSetDialog({double? initialWeight, int? initialReps}) {
    final weightController = TextEditingController(text: initialWeight?.toString() ?? '');
    final repsController = TextEditingController(text: initialReps?.toString() ?? '');
    return showDialog<_SetInput>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar serie'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: weightController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Peso (kg)', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reps', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_SetInput(
              weight: double.tryParse(weightController.text.replaceAll(',', '.')),
              reps: int.tryParse(repsController.text),
            )),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final setsAsync = ref.watch(setsForExerciseProvider(widget.sessionExerciseId));
    final sets = setsAsync.valueOrNull ?? const <WorkoutSet>[];

    return Scaffold(
      appBar: AppBar(title: Text(widget.exerciseName)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSet(sets),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _showRestTimer
          ? RestTimerBanner(
              key: ValueKey(_restNonce),
              seconds: widget.restSeconds,
              onFinished: () => setState(() => _showRestTimer = false),
            )
          : null,
      body: setsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (sets) {
          if (sets.isEmpty) {
            return Center(
              child: Text(
                'Añade la primera serie con el botón +.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sets.length,
            itemBuilder: (context, index) {
              final set = sets[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${set.setNumber}')),
                title: Text('${set.weightKg ?? '—'} kg × ${set.reps ?? '—'} reps'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref.read(sessionLoggingDaoProvider).deleteSet(set.id),
                ),
                onTap: () => _editSet(set),
              );
            },
          );
        },
      ),
    );
  }
}

class _SetInput {
  const _SetInput({required this.weight, required this.reps});
  final double? weight;
  final int? reps;
}
