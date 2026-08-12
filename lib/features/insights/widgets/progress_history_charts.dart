import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weight_unit.dart';
import '../../../core/widgets/app_card.dart';
import '../../../services/insights_engine/progress_history.dart';

// Shared x-axis label — "d MMM" for the Monday each week starts on, showing
// only every other week (or every week if there's room) so labels never
// overlap regardless of weekCount.
Widget _weekLabel(BuildContext context, List<DateTime> weeks, double value, {int everyN = 2}) {
  final index = value.round();
  if (index < 0 || index >= weeks.length || index % everyN != 0) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      DateFormat('d MMM', 'es').format(weeks[index]),
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

class VolumeHistoryChart extends StatelessWidget {
  const VolumeHistoryChart({super.key, required this.history, required this.unit});

  final ProgressHistory history;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final values = [for (final v in history.volume) kgToDisplayUnit(v.volume, unit)];
    final maxY = values.fold<double>(0, (a, b) => b > a ? b : a);

    return AppCard(
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY <= 0 ? 1 : maxY * 1.2,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) => _weekLabel(context, history.weeks, value),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
                isCurved: true,
                color: AppTheme.accent,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: AppTheme.accent.withValues(alpha: 0.15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FrequencyHistoryChart extends StatelessWidget {
  const FrequencyHistoryChart({super.key, required this.history});

  final ProgressHistory history;

  @override
  Widget build(BuildContext context) {
    final maxSessions = history.frequency.fold<int>(0, (a, b) => b.sessions > a ? b.sessions : a);

    return AppCard(
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            maxY: (maxSessions <= 0 ? 1 : maxSessions).toDouble() + 1,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) => _weekLabel(context, history.weeks, value),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < history.frequency.length; i++)
                BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: history.frequency[i].sessions.toDouble(),
                    color: AppTheme.statusCompleted,
                    width: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}

const _muscleTrendColors = [
  AppTheme.accent,
  AppTheme.statusPlanned,
  AppTheme.statusRest,
  AppTheme.statusSkipped,
];

class MuscleTrendChart extends StatelessWidget {
  const MuscleTrendChart({super.key, required this.history});

  final ProgressHistory history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (history.muscleTrends.isEmpty) {
      return AppCard(
        child: Text(
          'Todavía no hay suficientes datos para ver la evolución por músculo.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }
    final maxY = history.muscleTrends
        .expand((t) => t.weeklyVolumes)
        .fold<double>(0, (a, b) => b > a ? b : a);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY <= 0 ? 1 : maxY * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => _weekLabel(context, history.weeks, value),
                    ),
                  ),
                ),
                lineBarsData: [
                  for (var t = 0; t < history.muscleTrends.length; t++)
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < history.muscleTrends[t].weeklyVolumes.length; i++)
                          FlSpot(i.toDouble(), history.muscleTrends[t].weeklyVolumes[i]),
                      ],
                      isCurved: true,
                      color: _muscleTrendColors[t % _muscleTrendColors.length],
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (var t = 0; t < history.muscleTrends.length; t++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _muscleTrendColors[t % _muscleTrendColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(history.muscleTrends[t].muscle, style: theme.textTheme.bodySmall),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
