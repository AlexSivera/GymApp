import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/dashboard_providers.dart';

const _weekdayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

class WeeklyGoalCard extends StatelessWidget {
  const WeeklyGoalCard({super.key, required this.goal});

  final WeeklyGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayIndex = DateTime.now().weekday - 1; // 0 = Monday

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
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                _DayDot(
                  label: _weekdayLabels[i],
                  done: goal.completedByWeekday[i],
                  isToday: i == todayIndex,
                  isFuture: i > todayIndex,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.label,
    required this.done,
    required this.isToday,
    required this.isFuture,
  });

  final String label;
  final bool done;
  final bool isToday;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppTheme.statusCompleted;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? accent : Colors.transparent,
            border: Border.all(
              color: done
                  ? accent
                  : isToday
                      ? theme.colorScheme.primary
                      : AppTheme.border,
              width: isToday && !done ? 2 : 1,
            ),
          ),
          child: done
              ? const Icon(Icons.check, size: 18, color: Color(0xFF06201C))
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isFuture
                ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
