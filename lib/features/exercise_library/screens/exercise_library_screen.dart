import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/exercise_thumbnail.dart';
import '../../../data/database/app_database.dart';
import '../providers/exercise_library_providers.dart';
import 'create_exercise_screen.dart';
import 'exercise_detail_screen.dart';

// When [pickerMode] is true, tapping an exercise returns it to the caller
// via Navigator.pop instead of opening its detail page — used when adding
// an exercise to a routine day. The info button still opens the detail
// page in that case, without selecting the exercise.
class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key, this.pickerMode = false});

  final bool pickerMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exercises = ref.watch(filteredExercisesProvider);
    final muscles = ref.watch(availableMusclesProvider);
    final selectedMuscle = ref.watch(exerciseMuscleFilterProvider);
    final viewMode = ref.watch(exerciseViewModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(pickerMode ? 'Elegir ejercicio' : 'Ejercicios'),
        actions: [
          IconButton(
            tooltip: viewMode == ExerciseViewMode.list ? 'Ver en cuadrícula' : 'Ver en lista',
            icon: Icon(viewMode == ExerciseViewMode.list ? Icons.grid_view : Icons.view_list),
            onPressed: () => ref.read(exerciseViewModeProvider.notifier).state =
                viewMode == ExerciseViewMode.list ? ExerciseViewMode.grid : ExerciseViewMode.list,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const CreateExerciseScreen())),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar ejercicio',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => ref.read(exerciseSearchQueryProvider.notifier).state = value,
            ),
          ),
          if (muscles.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Todos'),
                      selected: selectedMuscle == null,
                      onSelected: (_) =>
                          ref.read(exerciseMuscleFilterProvider.notifier).state = null,
                    ),
                  ),
                  for (final muscle in muscles)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(muscle),
                        selected: selectedMuscle == muscle,
                        onSelected: (_) =>
                            ref.read(exerciseMuscleFilterProvider.notifier).state = muscle,
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: exercises.isEmpty
                ? Center(
                    child: Text(
                      'No se encontraron ejercicios.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                : viewMode == ExerciseViewMode.list
                    ? _ExerciseListView(exercises: exercises, pickerMode: pickerMode)
                    : _ExerciseGridView(exercises: exercises, pickerMode: pickerMode),
          ),
        ],
      ),
    );
  }
}

void _openExercise(BuildContext context, bool pickerMode, Exercise exercise) {
  if (pickerMode) {
    Navigator.of(context).pop(exercise);
  } else {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: exercise)));
  }
}

void _openDetail(BuildContext context, Exercise exercise) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: exercise)));
}

class _ExerciseListView extends StatelessWidget {
  const _ExerciseListView({required this.exercises, required this.pickerMode});

  final List<Exercise> exercises;
  final bool pickerMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return ListTile(
          leading: ExerciseThumbnail(imagePaths: exercise.imagePaths),
          title: Text(exercise.name),
          subtitle: Text(exercise.primaryMuscles.join(', ')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (exercise.isCustom)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.person_outline, color: theme.colorScheme.primary, size: 18),
                ),
              if (pickerMode)
                IconButton(
                  tooltip: 'Ver ficha',
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _openDetail(context, exercise),
                ),
            ],
          ),
          onTap: () => _openExercise(context, pickerMode, exercise),
        );
      },
    );
  }
}

class _ExerciseGridView extends StatelessWidget {
  const _ExerciseGridView({required this.exercises, required this.pickerMode});

  final List<Exercise> exercises;
  final bool pickerMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openExercise(context, pickerMode, exercise),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ExerciseImage(imagePaths: exercise.imagePaths, iconSize: 36),
                      ),
                    ),
                    if (pickerMode)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _InfoBadge(onTap: () => _openDetail(context, exercise)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                exercise.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                exercise.primaryMuscles.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.info_outline, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
