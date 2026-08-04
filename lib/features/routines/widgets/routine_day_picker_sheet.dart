import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/database/app_database.dart';
import '../providers/routines_providers.dart';

// Shared "pick a routine day" flow used by Home ("Elegir rutina") and the
// Calendar's day-detail / quick-assign actions. Pops the chosen [RoutineDay].
Future<RoutineDay?> showRoutineDayPicker(BuildContext context) {
  return showModalBottomSheet<RoutineDay>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const RoutineDayPickerSheet(),
  );
}

class RoutineDayPickerSheet extends ConsumerWidget {
  const RoutineDayPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesListProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Elegir rutina', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: routinesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('$e'),
                data: (routines) {
                  if (routines.isEmpty) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Todavía no tienes rutinas creadas.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.go('/routines');
                            },
                            child: const Text('Crear rutina'),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: routines.length,
                    itemBuilder: (context, index) => _RoutineExpansion(routine: routines[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineExpansion extends ConsumerWidget {
  const _RoutineExpansion({required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(routineDaysProvider(routine.id));

    return ExpansionTile(
      title: Text(routine.name, style: Theme.of(context).textTheme.titleMedium),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
      children: [
        daysAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text('$e'),
          data: (days) {
            if (days.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text('Esta rutina no tiene días todavía.'),
              );
            }
            return Column(
              children: [
                for (final day in days)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(day.name),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => Navigator.of(context).pop(day),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
