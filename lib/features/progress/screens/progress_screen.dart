import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exercise_library/providers/exercise_library_providers.dart';
import 'exercise_progress_screen.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exercisesAsync = ref.watch(allExercisesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progreso')),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (exercises) {
          if (exercises.isEmpty) {
            return Center(
              child: Text(
                'Todavía no hay ejercicios.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            );
          }
          return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return ListTile(
                title: Text(exercise.name),
                subtitle: Text(exercise.primaryMuscles.join(', ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ExerciseProgressScreen(
                    exerciseId: exercise.id,
                    exerciseName: exercise.name,
                  ),
                )),
              );
            },
          );
        },
      ),
    );
  }
}
