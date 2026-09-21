import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../screens/session_history_screen.dart';
import 'session_activity_row.dart';

// Replaces the old single "Último entrenamiento" card with a short feed of
// the last few real completed sessions — same underlying data, more context
// at a glance.
class RecentActivityCard extends ConsumerWidget {
  const RecentActivityCard({super.key, required this.sessions});

  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACTIVIDAD RECIENTE', style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.6)),
          const SizedBox(height: AppSpacing.md),
          if (sessions.isEmpty)
            Text(
              'Todavía no has registrado ningún entrenamiento.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            for (var i = 0; i < sessions.length; i++) ...[
              SessionActivityRow(session: sessions[i]),
              if (i != sessions.length - 1) const Divider(height: AppSpacing.lg),
            ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SessionHistoryScreen()),
              ),
              child: const Text('Ver historial →'),
            ),
          ),
        ],
      ),
    );
  }
}
