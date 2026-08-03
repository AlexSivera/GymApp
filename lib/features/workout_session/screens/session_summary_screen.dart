import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';
import '../../../services/insights_engine/session_summary.dart';

class SessionSummaryScreen extends StatelessWidget {
  const SessionSummaryScreen({super.key, required this.summary});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImprovements = summary.improvements.isNotEmpty;
    final hasPRs = summary.newPRs.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Entrenamiento completado')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Volumen total', style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('${summary.volumeThisSession.toStringAsFixed(0)} kg',
                    style: theme.textTheme.headlineMedium),
                if (summary.volumeChangePercent != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${summary.volumeChangePercent! >= 0 ? '+' : ''}${summary.volumeChangePercent!.toStringAsFixed(0)}% vs la última vez con esta rutina',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: summary.volumeChangePercent! >= 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasPRs) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nuevos récords personales', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final name in summary.newPRs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Text('🏆 '),
                          Expanded(child: Text(name)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (hasImprovements) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mejoras', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final improvement in summary.improvements)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${improvement.exerciseName} ${improvement.message}')),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (!hasImprovements && !hasPRs) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Text(
                'Sigue así — la próxima vez podrás comparar con esta sesión.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    );
  }
}
