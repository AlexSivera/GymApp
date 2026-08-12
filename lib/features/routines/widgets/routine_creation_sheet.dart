import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/database_provider.dart';
import '../../../data/routine_templates.dart';
import '../screens/create_routine_screen.dart';
import '../screens/routine_editor_screen.dart';

// Entry point for the "+" / "Crear tu primera rutina" actions — offers a
// blank routine (the original flow) or one of a few predefined templates
// that get instantiated immediately and dropped straight into the editor,
// so starting from Push/Pull/Legs takes one tap instead of adding five
// exercises by hand.
Future<void> showRoutineCreationSheet(BuildContext context, WidgetRef ref) async {
  final choice = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _RoutineCreationSheet(),
  );
  if (choice == null || !context.mounted) return;

  if (choice is RoutineTemplate) {
    final db = ref.read(appDatabaseProvider);
    final routineId = await instantiateRoutineTemplate(db, choice);
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoutineEditorScreen(routineId: routineId)));
  } else {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateRoutineScreen()));
  }
}

class _RoutineCreationSheet extends StatelessWidget {
  const _RoutineCreationSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Crear rutina', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.edit_note, color: theme.colorScheme.primary),
                title: const Text('Desde cero'),
                subtitle: const Text('Elige tus propios ejercicios'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pop('scratch'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('O empieza desde una plantilla',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.sm),
            for (final template in routineTemplates)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(Icons.list_alt, color: theme.colorScheme.primary),
                    title: Text(template.name),
                    subtitle: Text(template.description),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pop(template),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
