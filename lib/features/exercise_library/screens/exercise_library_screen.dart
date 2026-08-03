import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/exercise_thumbnail.dart';
import '../providers/exercise_library_providers.dart';
import 'create_exercise_screen.dart';
import 'exercise_detail_screen.dart';

// When [pickerMode] is true, tapping an exercise returns it to the caller
// via Navigator.pop instead of opening its detail page — used when adding
// an exercise to a routine day.
class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key, this.pickerMode = false});

  final bool pickerMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exercises = ref.watch(filteredExercisesProvider);
    final muscles = ref.watch(availableMusclesProvider);
    final selectedMuscle = ref.watch(exerciseMuscleFilterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(pickerMode ? 'Elegir ejercicio' : 'Ejercicios')),
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
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return ListTile(
                        leading: ExerciseThumbnail(imagePaths: exercise.imagePaths),
                        title: Text(exercise.name),
                        subtitle: Text(exercise.primaryMuscles.join(', ')),
                        trailing: exercise.isCustom
                            ? Icon(Icons.person_outline, color: theme.colorScheme.primary, size: 18)
                            : null,
                        onTap: () => pickerMode
                            ? Navigator.of(context).pop(exercise)
                            : Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: exercise)),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
