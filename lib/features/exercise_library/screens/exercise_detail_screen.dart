import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Músculos principales', value: exercise.primaryMuscles.join(', ')),
                if (exercise.secondaryMuscles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Músculos secundarios', value: exercise.secondaryMuscles.join(', ')),
                ],
                if (exercise.equipment != null) ...[
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Equipamiento', value: exercise.equipment!),
                ],
              ],
            ),
          ),
          if (exercise.instructions != null && exercise.instructions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Instrucciones', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(exercise.instructions!, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
