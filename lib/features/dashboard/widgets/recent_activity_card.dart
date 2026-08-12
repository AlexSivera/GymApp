import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/format_duration.dart';
import '../../../core/utils/weight_unit_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/insights_engine/session_summary.dart';
import '../../routines/providers/routines_providers.dart';
import '../../workout_session/screens/session_summary_screen.dart';
import '../providers/dashboard_providers.dart';

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
              _ActivityRow(session: sessions[i]),
              if (i != sessions.length - 1) const Divider(height: AppSpacing.lg),
            ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go('/calendar'),
              child: const Text('Ver historial →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends ConsumerWidget {
  const _ActivityRow({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dayName = ref.watch(routineDaySessionTitleProvider(session.routineDayId)) ?? 'Entrenamiento libre';
    final exerciseCount = ref.watch(sessionExerciseCountProvider(session.id)).valueOrNull;
    final duration = session.durationSeconds;

    return InkWell(
      onTap: () => _openSummary(context, ref, session),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dayLabel(session.date),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(dayName, style: theme.textTheme.titleMedium),
                  Text(
                    [
                      if (duration != null) formatWorkoutDuration(duration),
                      if (exerciseCount != null) '$exerciseCount ejercicios',
                    ].join(' · '),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Future<void> _openSummary(BuildContext context, WidgetRef ref, WorkoutSession session) async {
    final db = ref.read(appDatabaseProvider);
    final summary = await computeSessionSummary(db, sessionId: session.id, unit: ref.read(weightUnitProvider));
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SessionSummaryScreen(summary: summary)));
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    final label = DateFormat('EEEE', 'es').format(date);
    return label[0].toUpperCase() + label.substring(1);
  }
}
