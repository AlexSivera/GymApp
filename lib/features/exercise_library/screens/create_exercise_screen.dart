import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/muscle_groups.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';

// A minimal "add your own exercise" form for anything missing from the
// 150-exercise catalog. Saved with isCustom: true (the badge for that
// already existed in the library list/grid — this is what actually feeds it).
class CreateExerciseScreen extends ConsumerStatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  ConsumerState<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends ConsumerState<CreateExerciseScreen> {
  final _nameController = TextEditingController();
  final _equipmentController = TextEditingController();
  ExerciseCategory _category = ExerciseCategory.strength;
  final Set<String> _primaryMuscles = {};
  final Set<String> _secondaryMuscles = {};
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final id = await ref.read(appDatabaseProvider).exercisesDao.insert(ExercisesCompanion.insert(
            name: name,
            primaryMuscles: Value(_primaryMuscles.toList()),
            secondaryMuscles: Value(_secondaryMuscles.toList()),
            equipment: Value(
                _equipmentController.text.trim().isEmpty ? null : _equipmentController.text.trim()),
            category: Value(_category),
            isCustom: const Value(true),
          ));
      if (mounted) Navigator.of(context).pop(id);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = groupedAvailableMuscles(muscleGroups.values.expand((v) => v).toList());

    return Scaffold(
      appBar: AppBar(title: const Text('Crear ejercicio')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre', hintText: 'Ej. Remo en máquina Hammer'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Categoría', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ExerciseCategory>(
            segments: const [
              ButtonSegment(value: ExerciseCategory.strength, label: Text('Fuerza')),
              ButtonSegment(value: ExerciseCategory.cardio, label: Text('Cardio')),
              ButtonSegment(value: ExerciseCategory.isometric, label: Text('Isométrico')),
            ],
            selected: {_category},
            onSelectionChanged: (selection) => setState(() => _category = selection.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _equipmentController,
            decoration: const InputDecoration(labelText: 'Equipamiento (opcional)', hintText: 'Ej. Mancuernas'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Músculos principales', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: _MuscleChooser(
              grouped: grouped,
              selected: _primaryMuscles,
              onToggle: (muscle) => setState(() {
                if (!_primaryMuscles.remove(muscle)) _primaryMuscles.add(muscle);
                _secondaryMuscles.remove(muscle);
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Músculos secundarios (opcional)', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: _MuscleChooser(
              grouped: grouped,
              selected: _secondaryMuscles,
              onToggle: (muscle) => setState(() {
                if (_primaryMuscles.contains(muscle)) return;
                if (!_secondaryMuscles.remove(muscle)) _secondaryMuscles.add(muscle);
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSave ? _save : null,
              child: Text(_saving ? 'Guardando...' : 'Crear ejercicio'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleChooser extends StatelessWidget {
  const _MuscleChooser({required this.grouped, required this.selected, required this.onToggle});

  final Map<String, List<String>> grouped;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries) ...[
          Text(entry.key,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final muscle in entry.value)
                FilterChip(
                  label: Text(muscle),
                  selected: selected.contains(muscle),
                  onSelected: (_) => onToggle(muscle),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
