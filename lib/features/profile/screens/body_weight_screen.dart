import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/weight_unit.dart';
import '../../../core/utils/weight_unit_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../providers/profile_providers.dart';

class BodyWeightScreen extends ConsumerWidget {
  const BodyWeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(bodyWeightHistoryProvider);
    final unit = ref.watch(weightUnitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Peso corporal')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addEntry(context, ref),
        child: const Icon(Icons.add),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetryView(
          message: 'No se ha podido cargar tu historial de peso.',
          onRetry: () => ref.invalidate(bodyWeightHistoryProvider),
        ),
        data: (history) {
          if (history.isEmpty) {
            return Center(
              child: Text(
                'Registra tu primer peso con el botón +.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            );
          }
          final chronological = history.reversed.toList();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (chronological.length >= 2) _WeightChart(entries: chronological, unit: unit),
              const SizedBox(height: AppSpacing.lg),
              for (final log in history)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formatWeight(log.weightKg, unit), style: theme.textTheme.titleMedium),
                              Text(
                                DateFormat('EEEE d MMMM', 'es').format(log.date),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ref.read(appDatabaseProvider).bodyWeightDao.deleteLog(log.id),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addEntry(BuildContext context, WidgetRef ref) async {
    final unit = ref.read(weightUnitProvider);
    final controller = TextEditingController();
    final weight = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar peso'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: unit == WeightUnit.lb ? 'Ej. 173' : 'Ej. 78.5',
            suffixText: weightUnitLabel(unit),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(double.tryParse(controller.text.replaceAll(',', '.'))),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (weight == null) return;

    await ref.read(appDatabaseProvider).bodyWeightDao.insertLog(
          BodyWeightLogsCompanion.insert(date: DateTime.now(), weightKg: displayUnitToKg(weight, unit)),
        );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.entries, required this.unit});

  final List<BodyWeightLog> entries;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDate = entries.first.date;
    final spots = [
      for (final e in entries)
        FlSpot(e.date.difference(firstDate).inDays.toDouble(), kgToDisplayUnit(e.weightKg, unit)),
    ];
    final values = entries.map((e) => kgToDisplayUnit(e.weightKg, unit));
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.2 + 1;

    return AppCard(
      child: SizedBox(
        height: 200,
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
                  getTitlesWidget: (value, meta) =>
                      Text(value.toStringAsFixed(0), style: theme.textTheme.bodySmall),
                ),
              ),
              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: theme.colorScheme.primary,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData:
                    BarAreaData(show: true, color: theme.colorScheme.primary.withValues(alpha: 0.15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
