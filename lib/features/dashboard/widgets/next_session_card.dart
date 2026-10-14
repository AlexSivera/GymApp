import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../../routines/providers/routines_providers.dart';

class NextSessionCard extends ConsumerWidget {
  const NextSessionCard({super.key, required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dayName = ref.watch(routineDaySessionTitleProvider(session.routineDayId));

    return AppCard(
      child: Row(
        children: [
          Icon(Icons.event_outlined, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRÓXIMO ENTRENAMIENTO',
                    style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.6)),
                const SizedBox(height: AppSpacing.xs),
                Text(dayName ?? 'Entrenamiento libre', style: theme.textTheme.titleMedium),
                Text(
                  DateFormat('EEEE d MMMM', 'es').format(session.date),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
