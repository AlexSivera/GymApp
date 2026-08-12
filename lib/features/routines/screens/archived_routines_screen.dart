import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_retry_card.dart';
import '../providers/routines_providers.dart';

// Rutinas archivadas are hidden from the main "Tus rutinas" list but kept
// (with their full history) rather than deleted — this is the only place
// to see them again and bring one back.
class ArchivedRoutinesScreen extends ConsumerWidget {
  const ArchivedRoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final archivedAsync = ref.watch(archivedRoutinesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rutinas archivadas')),
      body: archivedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ErrorRetryCard(
            message: 'No se han podido cargar las rutinas archivadas.',
            onRetry: () => ref.invalidate(archivedRoutinesListProvider),
          ),
        ),
        data: (routines) {
          if (routines.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'No tienes ninguna rutina archivada.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: routines.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final routine = routines[index];
              return AppCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(child: Text(routine.name, style: theme.textTheme.titleMedium)),
                    TextButton(
                      onPressed: () => ref.read(routinesDaoProvider).setArchived(routine.id, false),
                      child: const Text('Desarchivar'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
