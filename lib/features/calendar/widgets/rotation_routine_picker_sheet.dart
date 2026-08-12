import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_retry_card.dart';
import '../../routines/providers/routines_providers.dart';

// Multi-select equivalent of the quick-assign sheet's rotation picker, used
// when "Asignación rápida" is applied to an already-selected set of
// calendar days instead of a date range — no duration/rest-day controls
// since the days are already chosen. Pops the ordered routine ids.
Future<List<int>?> showRotationRoutinePicker(BuildContext context) {
  return showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const RotationRoutinePickerSheet(),
  );
}

class RotationRoutinePickerSheet extends ConsumerStatefulWidget {
  const RotationRoutinePickerSheet({super.key});

  @override
  ConsumerState<RotationRoutinePickerSheet> createState() => _RotationRoutinePickerSheetState();
}

class _RotationRoutinePickerSheetState extends ConsumerState<RotationRoutinePickerSheet> {
  final List<int> _routineIds = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routinesAsync = ref.watch(routinesListProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.sm,
          bottom: AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asignación rápida', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Elige las rutinas, en el orden en que las toques, para repartirlas entre los días seleccionados.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            routinesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => ErrorRetryCard(
                message: 'No se han podido cargar tus rutinas.',
                onRetry: () => ref.invalidate(routinesListProvider),
              ),
              data: (routines) {
                if (routines.isEmpty) {
                  return Text(
                    'Crea una rutina primero.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  );
                }
                final routinesById = {for (final r in routines) r.id: r};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final r in routines)
                          FilterChip(
                            label: Text(r.name),
                            selected: _routineIds.contains(r.id),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                _routineIds.add(r.id);
                              } else {
                                _routineIds.remove(r.id);
                              }
                            }),
                          ),
                      ],
                    ),
                    if (_routineIds.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Se repetirá: ${_routineIds.map((id) => routinesById[id]?.name ?? '?').join(' → ')}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _routineIds.isEmpty ? null : () => Navigator.of(context).pop(_routineIds),
                child: const Text('Aplicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
