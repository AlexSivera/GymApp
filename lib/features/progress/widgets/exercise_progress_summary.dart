import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../providers/progress_providers.dart';

// Best weight/1RM cards + 1RM-over-time chart for one exercise — the
// "Resumen" tab on the exercise rank detail screen. No Scaffold/AppBar of
// its own so it can be embedded directly in a TabBarView.
class ExerciseProgressSummary extends ConsumerWidget {
  const ExerciseProgressSummary({super.key, required this.exerciseId});

  final int exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(oneRepMaxHistoryProvider(exerciseId));
    final recordsAsync = ref.watch(personalRecordsForExerciseProvider(exerciseId));

    final bestWeight = _bestOf(recordsAsync.valueOrNull, PersonalRecordType.maxWeight);
    final bestOneRm = _bestOf(recordsAsync.valueOrNull, PersonalRecordType.estimatedOneRepMax);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mejor peso',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      bestWeight == null ? '—' : '${_fmt(bestWeight.value)} kg',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1RM estimado',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      bestOneRm == null ? '—' : '${_fmt(bestOneRm.value)} kg',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
          data: (points) {
            if (points.length < 2) {
              return AppCard(
                child: Text(
                  points.isEmpty
                      ? 'Todavía no tienes datos de este ejercicio.'
                      : 'Necesitas entrenar este ejercicio en al menos dos días distintos para ver la evolución.',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              );
            }

            final firstDate = points.first.date;
            final spots = [
              for (final p in points) FlSpot(p.date.difference(firstDate).inDays.toDouble(), p.value)
            ];
            final minY = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
            final maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
            final padding = (maxY - minY) * 0.15 + 1;

            return AppCard(
              child: SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: minY - padding,
                    maxY: maxY + padding,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            value.toStringAsFixed(0),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: (spots.last.x - spots.first.x).clamp(1, double.infinity) / 3,
                          getTitlesWidget: (value, meta) {
                            final date = firstDate.add(Duration(days: value.round()));
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                DateFormat('d MMM', 'es').format(date),
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: theme.colorScheme.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  PersonalRecord? _bestOf(List<PersonalRecord>? records, PersonalRecordType type) {
    if (records == null) return null;
    final matching = records.where((r) => r.type == type);
    if (matching.isEmpty) return null;
    return matching.reduce((a, b) => a.value > b.value ? a : b);
  }

  String _fmt(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}
