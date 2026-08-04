import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
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
    final tab = ref.watch(exerciseLibraryTabProvider);
    final viewMode = ref.watch(exerciseViewModeProvider);
    final favoriteIds = ref.watch(favoriteExerciseIdsProvider).valueOrNull?.toSet() ?? const {};

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
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final t in ExerciseLibraryTab.values)
                  ChoiceChip(
                    label: Text(_tabLabel(t)),
                    selected: tab == t,
                    onSelected: (_) => ref.read(exerciseLibraryTabProvider.notifier).state = t,
                  ),
              ],
            ),
          ),
          if (tab == ExerciseLibraryTab.all) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar ejercicio',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (value) => ref.read(exerciseSearchQueryProvider.notifier).state = value,
              ),
            ),
            _MuscleChipRow(),
          ],
          Expanded(
            child: switch (tab) {
              ExerciseLibraryTab.categories => _CategoriesTab(),
              ExerciseLibraryTab.recent => _ExerciseCollection(
                  exercises: ref.watch(recentExercisesProvider),
                  emptyMessage: 'Todavía no has usado ningún ejercicio.',
                  pickerMode: pickerMode,
                  viewMode: viewMode,
                  favoriteIds: favoriteIds,
                ),
              ExerciseLibraryTab.favorites => _ExerciseCollection(
                  exercises: ref.watch(favoriteExercisesProvider),
                  emptyMessage: 'Marca ejercicios como favoritos para verlos aquí.',
                  pickerMode: pickerMode,
                  viewMode: viewMode,
                  favoriteIds: favoriteIds,
                ),
              ExerciseLibraryTab.all => _ExerciseCollection(
                  exercises: ref.watch(filteredExercisesProvider),
                  emptyMessage: 'No se encontraron ejercicios.',
                  pickerMode: pickerMode,
                  viewMode: viewMode,
                  favoriteIds: favoriteIds,
                ),
            },
          ),
        ],
      ),
    );
  }

  String _tabLabel(ExerciseLibraryTab tab) {
    switch (tab) {
      case ExerciseLibraryTab.recent:
        return 'Recientes';
      case ExerciseLibraryTab.favorites:
        return 'Favoritos';
      case ExerciseLibraryTab.categories:
        return 'Categorías';
      case ExerciseLibraryTab.all:
        return 'Todos';
    }
  }
}

class _MuscleChipRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscles = ref.watch(availableMusclesProvider);
    final selectedMuscle = ref.watch(exerciseMuscleFilterProvider);
    if (muscles.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: const Text('Todos'),
              selected: selectedMuscle == null,
              onSelected: (_) => ref.read(exerciseMuscleFilterProvider.notifier).state = null,
            ),
          ),
          for (final muscle in muscles)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(muscle),
                selected: selectedMuscle == muscle,
                onSelected: (_) => ref.read(exerciseMuscleFilterProvider.notifier).state = muscle,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoriesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscles = ref.watch(availableMusclesProvider);
    if (muscles.isEmpty) {
      return const Center(child: Text('Todavía no hay ejercicios.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 2,
      ),
      itemCount: muscles.length,
      itemBuilder: (context, index) {
        final muscle = muscles[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              ref.read(exerciseMuscleFilterProvider.notifier).state = muscle;
              ref.read(exerciseLibraryTabProvider.notifier).state = ExerciseLibraryTab.all;
            },
            child: Center(
              child: Text(muscle, style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
        );
      },
    );
  }
}

class _ExerciseCollection extends StatelessWidget {
  const _ExerciseCollection({
    required this.exercises,
    required this.emptyMessage,
    required this.pickerMode,
    required this.viewMode,
    required this.favoriteIds,
  });

  final List<Exercise> exercises;
  final String emptyMessage;
  final bool pickerMode;
  final ExerciseViewMode viewMode;
  final Set<int> favoriteIds;

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }
    return viewMode == ExerciseViewMode.list
        ? _ExerciseListView(exercises: exercises, pickerMode: pickerMode, favoriteIds: favoriteIds)
        : _ExerciseGridView(exercises: exercises, pickerMode: pickerMode, favoriteIds: favoriteIds);
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

class _ExerciseListView extends ConsumerWidget {
  const _ExerciseListView({required this.exercises, required this.pickerMode, required this.favoriteIds});

  final List<Exercise> exercises;
  final bool pickerMode;
  final Set<int> favoriteIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final isFavorite = favoriteIds.contains(exercise.id);
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
              IconButton(
                icon: Icon(isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Colors.amber : theme.colorScheme.onSurfaceVariant),
                onPressed: () => ref.read(favoritesDaoProvider).toggleFavorite(exercise.id),
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

class _ExerciseGridView extends ConsumerWidget {
  const _ExerciseGridView({required this.exercises, required this.pickerMode, required this.favoriteIds});

  final List<Exercise> exercises;
  final bool pickerMode;
  final Set<int> favoriteIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        final isFavorite = favoriteIds.contains(exercise.id);
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
                    Positioned(
                      top: 4,
                      left: 4,
                      child: _RoundIconButton(
                        icon: isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite ? Colors.amber : Colors.white,
                        onTap: () => ref.read(favoritesDaoProvider).toggleFavorite(exercise.id),
                      ),
                    ),
                    if (pickerMode)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _RoundIconButton(
                          icon: Icons.info_outline,
                          onTap: () => _openDetail(context, exercise),
                        ),
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap, this.color = Colors.white});

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
