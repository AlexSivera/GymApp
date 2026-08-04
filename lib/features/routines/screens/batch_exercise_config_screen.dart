import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/exercise_thumbnail.dart';
import '../../../data/database/app_database.dart';
import '../models/exercise_config.dart';

// Configure sets/reps/RIR/rest for every exercise picked in one multi-select
// batch, all on one screen instead of one dialog per exercise. Pops a
// Map<exerciseId, ExerciseConfig> (or null if cancelled).
class BatchExerciseConfigScreen extends StatefulWidget {
  const BatchExerciseConfigScreen({super.key, required this.exercises});

  final List<Exercise> exercises;

  @override
  State<BatchExerciseConfigScreen> createState() => _BatchExerciseConfigScreenState();
}

class _BatchExerciseConfigScreenState extends State<BatchExerciseConfigScreen> {
  late final Map<int, ExerciseConfig> _configs = {
    for (final e in widget.exercises) e.id: ExerciseConfig.defaults,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Configurar ${widget.exercises.length} ejercicios')),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: widget.exercises.length,
        itemBuilder: (context, index) {
          final exercise = widget.exercises[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ExerciseConfigCard(
              exercise: exercise,
              initial: _configs[exercise.id]!,
              onChanged: (config) => _configs[exercise.id] = config,
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_configs),
              child: Text('Añadir ${widget.exercises.length} ejercicio${widget.exercises.length == 1 ? '' : 's'}'),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseConfigCard extends StatefulWidget {
  const _ExerciseConfigCard({required this.exercise, required this.initial, required this.onChanged});

  final Exercise exercise;
  final ExerciseConfig initial;
  final ValueChanged<ExerciseConfig> onChanged;

  @override
  State<_ExerciseConfigCard> createState() => _ExerciseConfigCardState();
}

class _ExerciseConfigCardState extends State<_ExerciseConfigCard> {
  late final TextEditingController _sets;
  late final TextEditingController _repsMin;
  late final TextEditingController _repsMax;
  late final TextEditingController _rir;
  late final TextEditingController _rest;

  @override
  void initState() {
    super.initState();
    _sets = TextEditingController(text: '${widget.initial.sets}');
    _repsMin = TextEditingController(text: '${widget.initial.repsMin}');
    _repsMax = TextEditingController(text: '${widget.initial.repsMax}');
    _rir = TextEditingController(text: widget.initial.rir?.toString() ?? '');
    _rest = TextEditingController(text: widget.initial.restSeconds?.toString() ?? '');
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

  void _emit() {
    widget.onChanged(ExerciseConfig(
      sets: int.tryParse(_sets.text) ?? widget.initial.sets,
      repsMin: int.tryParse(_repsMin.text) ?? widget.initial.repsMin,
      repsMax: int.tryParse(_repsMax.text) ?? widget.initial.repsMax,
      rir: int.tryParse(_rir.text),
      restSeconds: int.tryParse(_rest.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExerciseThumbnail(imagePaths: widget.exercise.imagePaths),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(widget.exercise.name, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _numberField(_sets, 'Series')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _numberField(_repsMin, 'Reps mín.')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _numberField(_repsMax, 'Reps máx.')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _numberField(_rir, 'RIR (opcional)')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _numberField(_rest, 'Descanso (s)')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, isDense: true),
      onChanged: (_) => _emit(),
    );
  }
}
