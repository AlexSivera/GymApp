import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/exercise_thumbnail.dart';
import '../../../data/database/app_database.dart';
import '../providers/exercise_library_providers.dart';
import 'exercise_detail_screen.dart';

// Selection state for multiSelect mode — a plain provider (not tied to this
// widget's lifecycle) so it doesn't matter that ExerciseLibraryScreen is
// stateless; autoDispose clears it once nothing is watching (i.e. once the
// screen is popped).
final _multiSelectionProvider = StateProvider.autoDispose<Set<int>>((ref) => {});

// When [pickerMode] is true, tapping an exercise returns it to the caller
// via Navigator.pop instead of opening its detail page — used when adding
// an exercise to a routine day. The info button still opens the detail
// page in that case, without selecting the exercise.
//
// When [multiSelect] is also true, tapping toggles a checkbox instead, and
// a bottom bar lets the user confirm the whole batch — pops a
// `List<Exercise>` instead of a single `Exercise`.
class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key, this.pickerMode = false, this.multiSelect = false});

  final bool pickerMode;
  final bool multiSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(exerciseLibraryTabProvider);
    final viewMode = ref.watch(exerciseViewModeProvider);
    final selectedIds = multiSelect ? ref.watch(_multiSelectionProvider) : const <int>{};

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
                  multiSelect: multiSelect,
                  selectedIds: selectedIds,
                ),
              ExerciseLibraryTab.all => _ExerciseCollection(
                  exercises: ref.watch(filteredExercisesProvider),
                  emptyMessage: 'No se encontraron ejercicios.',
                  pickerMode: pickerMode,
                  viewMode: viewMode,
                  multiSelect: multiSelect,
                  selectedIds: selectedIds,
                ),
            },
          ),
        ],
      ),
      bottomNavigationBar: multiSelect ? _MultiSelectBar(selectedIds: selectedIds) : null,
    );
  }

  String _tabLabel(ExerciseLibraryTab tab) {
    switch (tab) {
      case ExerciseLibraryTab.recent:
        return 'Recientes';
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
        final theme = Theme.of(context);
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              ref.read(exerciseMuscleFilterProvider.notifier).state = muscle;
              ref.read(exerciseLibraryTabProvider.notifier).state = ExerciseLibraryTab.all;
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.fitness_center, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(muscle, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
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
    required this.multiSelect,
    required this.selectedIds,
  });

  final List<Exercise> exercises;
  final String emptyMessage;
  final bool pickerMode;
  final ExerciseViewMode viewMode;
  final bool multiSelect;
  final Set<int> selectedIds;

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
        ? _ExerciseListView(
            exercises: exercises,
            pickerMode: pickerMode,
            multiSelect: multiSelect,
            selectedIds: selectedIds,
          )
        : _ExerciseGridView(
            exercises: exercises,
            pickerMode: pickerMode,
            multiSelect: multiSelect,
            selectedIds: selectedIds,
          );
  }
}

void _openExercise(BuildContext context, WidgetRef ref, bool pickerMode, bool multiSelect, Exercise exercise) {
  if (multiSelect) {
    final current = {...ref.read(_multiSelectionProvider)};
    if (!current.remove(exercise.id)) current.add(exercise.id);
    ref.read(_multiSelectionProvider.notifier).state = current;
  } else if (pickerMode) {
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
  const _ExerciseListView({
    required this.exercises,
    required this.pickerMode,
    required this.multiSelect,
    required this.selectedIds,
  });

  final List<Exercise> exercises;
  final bool pickerMode;
  final bool multiSelect;
  final Set<int> selectedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 80),
      itemCount: exercises.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final isSelected = selectedIds.contains(exercise.id);
        return AppCard(
          padding: EdgeInsets.zero,
          child: ListTile(
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
                if (pickerMode && !multiSelect)
                  IconButton(
                    tooltip: 'Ver ficha',
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _openDetail(context, exercise),
                  ),
                if (multiSelect)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _openExercise(context, ref, pickerMode, multiSelect, exercise),
                  ),
              ],
            ),
            onTap: () => _openExercise(context, ref, pickerMode, multiSelect, exercise),
          ),
        );
      },
    );
  }
}

class _ExerciseGridView extends ConsumerWidget {
  const _ExerciseGridView({
    required this.exercises,
    required this.pickerMode,
    required this.multiSelect,
    required this.selectedIds,
  });

  final List<Exercise> exercises;
  final bool pickerMode;
  final bool multiSelect;
  final Set<int> selectedIds;

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
        final isSelected = selectedIds.contains(exercise.id);
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openExercise(context, ref, pickerMode, multiSelect, exercise),
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
                    if (isSelected)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.primary, width: 3),
                          ),
                        ),
                      ),
                    // Selector (multiSelect) or the picker's info button both
                    // live on the right — the thumbnail itself is the only
                    // thing anchored to the left.
                    if (multiSelect)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _RoundIconButton(
                          icon: isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? theme.colorScheme.primary : Colors.white,
                          onTap: () => _openExercise(context, ref, pickerMode, multiSelect, exercise),
                        ),
                      )
                    else if (pickerMode)
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

class _MultiSelectBar extends ConsumerWidget {
  const _MultiSelectBar({required this.selectedIds});

  final Set<int> selectedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedIds.isEmpty
                ? null
                : () {
                    final all = [
                      ...ref.read(allExercisesProvider).valueOrNull ?? const <Exercise>[],
                    ];
                    final chosen = all.where((e) => selectedIds.contains(e.id)).toList();
                    Navigator.of(context).pop(chosen);
                  },
            child: Text(selectedIds.isEmpty
                ? 'Selecciona ejercicios'
                : 'Añadir ${selectedIds.length} ejercicio${selectedIds.length == 1 ? '' : 's'}'),
          ),
        ),
      ),
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
