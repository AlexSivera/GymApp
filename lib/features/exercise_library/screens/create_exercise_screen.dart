import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';

class CreateExerciseScreen extends ConsumerStatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  ConsumerState<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends ConsumerState<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _primaryMusclesController = TextEditingController();
  final _secondaryMusclesController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _primaryMusclesController.dispose();
    _secondaryMusclesController.dispose();
    _equipmentController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  List<String> _splitList(String text) => text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final dao = ref.read(appDatabaseProvider).exercisesDao;
    await dao.createCustomExercise(ExercisesCompanion.insert(
      name: _nameController.text.trim(),
      primaryMuscles: Value(_splitList(_primaryMusclesController.text)),
      secondaryMuscles: Value(_splitList(_secondaryMusclesController.text)),
      equipment: Value(_equipmentController.text.trim().isEmpty ? null : _equipmentController.text.trim()),
      instructions: Value(
          _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim()),
      isCustom: const Value(true),
    ));

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo ejercicio')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _primaryMusclesController,
                    decoration: const InputDecoration(
                      labelText: 'Músculos principales',
                      hintText: 'Ej. Pecho, Tríceps',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _secondaryMusclesController,
                    decoration: const InputDecoration(
                      labelText: 'Músculos secundarios',
                      hintText: 'Opcional',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _equipmentController,
                    decoration: const InputDecoration(labelText: 'Equipamiento'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _instructionsController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Instrucciones'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _save, child: const Text('Guardar ejercicio')),
            ),
          ],
        ),
      ),
    );
  }
}
