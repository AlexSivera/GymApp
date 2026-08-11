import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../services/insights_engine/weekly_summary.dart';

// Reuses the app's existing weekly-volume engine (already computed for the
// daily insight text) as a structured stat instead of inventing a new metric.
class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, required this.summary});

  final WeeklySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = AppTheme.statusRest;
    final changePercent = summary.volumeChangePercent;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TU PROGRESO', style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.6)),
          const SizedBox(height: AppSpacing.md),
          if (changePercent == null)
            Text(
              summary.sessionsThisWeek == 0
                  ? 'Entrena esta semana para ver tu progreso.'
                  : 'Sigue entrenando para comparar tu volumen semana a semana.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  changePercent >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: color,
                  size: 26,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                  style: theme.textTheme.headlineMedium?.copyWith(color: color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Volumen esta semana',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          if (summary.prsThisWeek > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined, color: AppTheme.accent, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${summary.prsThisWeek} ${summary.prsThisWeek == 1 ? 'récord nuevo' : 'récords nuevos'} esta semana',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
