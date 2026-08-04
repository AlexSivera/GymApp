import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/dashboard_providers.dart';

class WeeklyGoalCard extends StatelessWidget {
  const WeeklyGoalCard({super.key, required this.goal});

  final WeeklyGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goal.target <= 0 ? 0.0 : (goal.completed / goal.target).clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Objetivo semanal', style: theme.textTheme.titleMedium),
              Text(
                '${goal.completed} de ${goal.target}',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
