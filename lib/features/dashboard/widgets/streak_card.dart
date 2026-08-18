import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';

// Gives the streak the "achievement" presence the old 2x2 stat grid didn't:
// a big number plus a row of pips echoing the current run, capped at 7 so a
// long streak doesn't overflow the card.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.of(context).statusPlanned;
    final filledPips = streak.clamp(0, 7);

    return AppCard(
      color: color.withValues(alpha: 0.08),
      borderColor: color.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded, size: 18, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'RACHA',
                style: theme.textTheme.labelMedium?.copyWith(color: color, letterSpacing: 0.6),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('$streak ${streak == 1 ? 'día' : 'días'}', style: theme.textTheme.displaySmall),
          const SizedBox(height: AppSpacing.sm),
          Text(_message(streak), style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i == 6 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: i < filledPips ? color : color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _message(int streak) {
    if (streak <= 0) return 'Entrena hoy para empezar tu racha';
    if (streak == 1) return '¡Buen comienzo, sigue así!';
    return '¡No rompas la racha!';
  }
}
