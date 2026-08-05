import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
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
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: routines.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
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
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(routine.name, style: theme.textTheme.titleMedium),
          iconColor: theme.colorScheme.primary,
          collapsedIconColor: theme.colorScheme.onSurfaceVariant,
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
          children: [
            daysAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text('$e'),
              data: (days) {
                if (days.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text('Esta rutina no tiene días todavía.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  );
                }
                return Column(
                  children: [
                    for (final day in days)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(day.name),
                        trailing: Icon(Icons.chevron_right,
                            size: 20, color: theme.colorScheme.onSurfaceVariant),
                        onTap: () => Navigator.of(context).pop(day),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
