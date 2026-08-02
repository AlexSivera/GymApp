import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';

class LastSessionCard extends StatelessWidget {
  const LastSessionCard({super.key, required this.session});

  final WorkoutSession? session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Último entrenamiento', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (session == null)
            Text(
              'Todavía no has registrado ningún entrenamiento.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            Text(
              DateFormat('EEEE d MMMM', 'es').format(session!.date),
              style: theme.textTheme.headlineMedium,
            ),
        ],
      ),
    );
  }
}
