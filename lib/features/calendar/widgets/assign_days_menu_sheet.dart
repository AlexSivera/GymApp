import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

enum AssignDaysAction { manual, selectMultiple, quickAssign }

// Single entry point for every way of putting a routine on the calendar —
// replaces the old separate "Asignación rápida" button and "Seleccionar
// días" toggle so the screen has one clearly-labeled action instead of two.
Future<AssignDaysAction?> showAssignDaysMenu(BuildContext context) {
  return showModalBottomSheet<AssignDaysAction>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AssignDaysMenuSheet(),
  );
}

class _AssignDaysMenuSheet extends StatelessWidget {
  const _AssignDaysMenuSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asignar días', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Elige cómo quieres planificar tus entrenamientos.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            _AssignDaysOption(
              icon: Icons.today_outlined,
              title: 'Día a día',
              subtitle: 'Toca un día del calendario y elige su rutina.',
              onTap: () => Navigator.of(context).pop(AssignDaysAction.manual),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AssignDaysOption(
              icon: Icons.checklist,
              title: 'Seleccionar varios días',
              subtitle: 'Elige días del calendario y asígnales una rutina o una asignación rápida.',
              onTap: () => Navigator.of(context).pop(AssignDaysAction.selectMultiple),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AssignDaysOption(
              icon: Icons.bolt_outlined,
              title: 'Asignación rápida',
              subtitle: 'Genera un plan automático para un rango de fechas.',
              onTap: () => Navigator.of(context).pop(AssignDaysAction.quickAssign),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignDaysOption extends StatelessWidget {
  const _AssignDaysOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
