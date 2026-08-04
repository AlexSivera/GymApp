import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/insights_engine/session_summary.dart';
import '../../workout_session/screens/session_summary_screen.dart';

class LastSessionCard extends ConsumerWidget {
  const LastSessionCard({super.key, required this.session});

  final WorkoutSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = this.session;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Último entrenamiento', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (session == null)
            Text(
              'Todavía no has registrado ningún entrenamiento.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          else ...[
            Text(DateFormat('EEEE d MMMM', 'es').format(session.date), style: theme.textTheme.titleLarge),
            Text(
              _timeAgo(session.date),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _openSummary(context, ref, session),
                child: const Text('Ver resumen'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openSummary(BuildContext context, WidgetRef ref, WorkoutSession session) async {
    final db = ref.read(appDatabaseProvider);
    final summary = await computeSessionSummary(db, sessionId: session.id);
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SessionSummaryScreen(summary: summary)));
  }

  String _timeAgo(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'Hoy';
    if (days == 1) return 'Ayer';
    return 'Hace $days días';
  }
}
