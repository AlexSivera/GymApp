import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/count_up_text.dart';

class CaloriesTodayCard extends StatelessWidget {
  const CaloriesTodayCard({super.key, required this.calories});

  final double calories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The flame keeps its warm color, but the number itself stays neutral —
    // a big red figure (or a red dash when empty) read as an error.
    final color = AppColors.of(context).statusSkipped;
    final hasData = calories > 0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department, color: color, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'CALORÍAS HOY',
                  style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (hasData)
            CountUpText(
              value: calories,
              format: (v) => '${v.round()}',
              style: theme.textTheme.displaySmall,
            )
          else
            Text('0', style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasData ? 'kcal quemadas' : 'Entrena para sumar kcal',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
