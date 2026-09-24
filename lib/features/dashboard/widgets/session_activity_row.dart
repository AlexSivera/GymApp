import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/format_duration.dart';
import '../../../core/utils/weight_unit_provider.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/insights_engine/session_summary.dart';
import '../../routines/providers/routines_providers.dart';
import '../../workout_session/screens/session_summary_screen.dart';
import '../providers/dashboard_providers.dart';

// Shared between the dashboard's "Actividad reciente" feed and the full
// session history screen so both list a completed session the same way.
class SessionActivityRow extends ConsumerWidget {
  const SessionActivityRow({super.key, required this.session});

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
                      if (exerciseCount != null) '$exerciseCount ${exerciseCount == 1 ? 'ejercicio' : 'ejercicios'}',
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
    final label = DateFormat('EEEE d MMMM', 'es').format(date);
    return label[0].toUpperCase() + label.substring(1);
  }
}
