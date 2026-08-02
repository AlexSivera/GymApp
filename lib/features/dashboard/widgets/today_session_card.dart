import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';

class TodaySessionCard extends StatelessWidget {
  const TodaySessionCard({super.key, required this.session});

  final WorkoutSession? session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (session == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hoy', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'No tienes ningún entrenamiento programado para hoy.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hoy', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            session!.routineDayId != null ? 'Entrenamiento planificado' : 'Entrenamiento libre',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            _statusLabel(session!.status),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _statusLabel(SessionStatus status) {
    switch (status) {
      case SessionStatus.planned:
        return 'Planificado';
      case SessionStatus.inProgress:
        return 'En curso';
      case SessionStatus.completed:
        return 'Completado';
      case SessionStatus.skipped:
        return 'Saltado';
    }
  }
}
