import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/weight_unit.dart';
import '../../../core/utils/weight_unit_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_retry_card.dart';
import '../providers/insights_providers.dart';
import '../widgets/progress_history_charts.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    final weeklyAsync = ref.watch(weeklySummaryProvider);
    final stagnantAsync = ref.watch(stagnantExercisesProvider);
    final balanceAsync = ref.watch(muscleBalanceProvider);
    final historyAsync = ref.watch(progressHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(weeklySummaryProvider);
              ref.invalidate(stagnantExercisesProvider);
              ref.invalidate(muscleBalanceProvider);
              ref.invalidate(progressHistoryProvider);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Resumen semanal', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          weeklyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorRetryCard(
              message: 'No se ha podido cargar el resumen semanal.',
              onRetry: () => ref.invalidate(weeklySummaryProvider),
            ),
            data: (summary) => AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${summary.sessionsThisWeek} entrenamiento${summary.sessionsThisWeek == 1 ? '' : 's'} esta semana',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('${summary.prsThisWeek} récord${summary.prsThisWeek == 1 ? '' : 's'} personal${summary.prsThisWeek == 1 ? '' : 'es'} nuevo${summary.prsThisWeek == 1 ? '' : 's'}'),
                  const SizedBox(height: 4),
                  Text(
                    summary.volumeChangePercent == null
                        ? 'Volumen: ${formatWeight(summary.volumeThisWeek, unit, decimals: 0)}'
                        : 'Volumen: ${formatWeight(summary.volumeThisWeek, unit, decimals: 0)} (${summary.volumeChangePercent! >= 0 ? '+' : ''}${summary.volumeChangePercent!.toStringAsFixed(0)}% vs semana pasada)',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Volumen semanal (últimas 8 semanas)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorRetryCard(
              message: 'No se ha podido cargar el historial de volumen.',
              onRetry: () => ref.invalidate(progressHistoryProvider),
            ),
            data: (history) => history.hasAnyData
                ? VolumeHistoryChart(history: history, unit: unit)
                : AppCard(
                    child: Text(
                      'Todavía no hay suficientes entrenamientos para ver una tendencia.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Text('Frecuencia de entrenamiento', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorRetryCard(
              message: 'No se ha podido cargar la frecuencia de entrenamiento.',
              onRetry: () => ref.invalidate(progressHistoryProvider),
            ),
            data: (history) => FrequencyHistoryChart(history: history),
          ),
          const SizedBox(height: 20),
          Text('Evolución por grupo muscular', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorRetryCard(
              message: 'No se ha podido cargar la evolución muscular.',
              onRetry: () => ref.invalidate(progressHistoryProvider),
            ),
            data: (history) => MuscleTrendChart(history: history),
          ),
          const SizedBox(height: 20),
          Text('Balance muscular (últimos 30 días)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          balanceAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorRetryCard(
              message: 'No se ha podido cargar el balance muscular.',
              onRetry: () => ref.invalidate(muscleBalanceProvider),
            ),
            data: (balance) {
              if (balance.isEmpty) {
                return AppCard(
                  child: Text(
                    'Todavía no hay suficiente datos de entrenamiento.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              }
              final maxVolume = balance.first.volume;
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (balance.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Músculo más atrasado: ${balance.last.muscle}',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ),
                    for (final m in balance)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.muscle, style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: maxVolume == 0 ? 0 : m.volume / maxVolume,
                                minHeight: 6,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text('Ejercicios estancados', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          stagnantAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorRetryCard(
              message: 'No se han podido cargar los ejercicios estancados.',
              onRetry: () => ref.invalidate(stagnantExercisesProvider),
            ),
            data: (stagnant) => AppCard(
              child: stagnant.isEmpty
                  ? Text(
                      'Ningún ejercicio parece estancado ahora mismo.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final ex in stagnant)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.trending_flat, size: 18, color: theme.colorScheme.error),
                                const SizedBox(width: 8),
                                Expanded(child: Text(ex.exerciseName)),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
