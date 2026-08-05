import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/exercise_thumbnail.dart';
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
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: exercises.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: ExerciseThumbnail(imagePaths: exercise.imagePaths),
                  title: Text(exercise.name, style: theme.textTheme.bodyLarge),
                  subtitle: Text(exercise.primaryMuscles.join(', ')),
                  trailing: Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ExerciseProgressScreen(
                      exerciseId: exercise.id,
                      exerciseName: exercise.name,
                    ),
                  )),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
