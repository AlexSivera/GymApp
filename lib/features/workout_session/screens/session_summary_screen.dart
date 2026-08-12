import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/weight_unit.dart';
import '../../../core/utils/weight_unit_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../../services/insights_engine/session_summary.dart';

class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({super.key, required this.summary});

  final SessionSummary summary;

  // This screen is pushed imperatively on top of whichever tab's own
  // navigator was active (Inicio, Calendario o Entreno), and that navigator
  // keeps its stack when switching tabs. A plain pop — which is what both
  // the system/gesture back button and the AppBar's default back arrow do —
  // just reveals whatever was directly underneath. From the "just finished a
  // workout" path that's the /workout branch's own root screen, which by
  // now renders a blank placeholder (the session is no longer active), so
  // the user lands on an apparently-frozen black screen. Pop back to the
  // tab's root first, then switch to Inicio — every exit from this screen
  // must go through this, not a bare pop.
  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    final hasImprovements = summary.improvements.isNotEmpty;
    final hasPRs = summary.newPRs.isNotEmpty;

    return CelebrationOverlay(
      child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goHome(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _goHome(context),
          ),
          title: Text(summary.routineDayName ?? 'Entrenamiento completado'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (summary.exerciseLogs.isNotEmpty) ...[
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < summary.exerciseLogs.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                summary.exerciseLogs[i].exerciseName,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              summary.exerciseLogs[i].setsSummary,
                              textAlign: TextAlign.end,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i != summary.exerciseLogs.length - 1)
                        const Divider(height: 1, indent: 16),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volumen total',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatWeight(summary.volumeThisSession, unit, decimals: 0),
                    style: theme.textTheme.headlineMedium,
                  ),
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
            if (summary.caloriesBurned > 0) ...[
              const SizedBox(height: 12),
              AppCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_outlined,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${summary.caloriesBurned.round()} kcal',
                            style: theme.textTheme.headlineMedium,
                          ),
                          Text(
                            'Calorías quemadas (estimado)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (hasPRs) ...[
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nuevos récords personales',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final name in summary.newPRs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              size: 16,
                              color: Color(0xFFFBBF24),
                            ),
                            const SizedBox(width: 6),
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
                            Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${improvement.exerciseName} ${improvement.message}',
                              ),
                            ),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _goHome(context),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
