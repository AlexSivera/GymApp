import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// Shared value axis for the progress charts: a "nice" step (1/2/5 × 10ⁿ) so
// the few labels read as round numbers, a top that lands exactly on a step,
// and faint dashed guide lines — before, the charts had no scale at all and
// you couldn't tell how much a bar or a point was worth.
class ChartValueAxis {
  ChartValueAxis._(this.step, this.max);

  factory ChartValueAxis.forMax(double dataMax, {int targetLines = 3}) {
    if (dataMax <= 0) return ChartValueAxis._(1, 1);
    final raw = dataMax / targetLines;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final normalized = raw / magnitude;
    final niceNormalized = normalized <= 1
        ? 1
        : normalized <= 2
            ? 2
            : normalized <= 5
                ? 5
                : 10;
    final step = niceNormalized * magnitude;
    final max = (dataMax * 1.08 / step).ceil() * step;
    return ChartValueAxis._(step, max);
  }

  final double step;
  final double max;

  static String compact(double value) {
    if (value >= 1000) {
      final thousands = value / 1000;
      final text = thousands == thousands.roundToDouble()
          ? thousands.toStringAsFixed(0)
          : thousands.toStringAsFixed(1);
      return '${text.replaceAll('.', ',')}k';
    }
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  AxisTitles titles(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 34,
        interval: step,
        getTitlesWidget: (value, meta) {
          // fl_chart also asks for the exact min/max; only label real steps.
          final onStep = (value / step - (value / step).round()).abs() < 0.001;
          if (!onStep) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(compact(value), style: style, textAlign: TextAlign.right),
          );
        },
      ),
    );
  }

  FlGridData grid(BuildContext context) {
    final color = AppColors.of(context).border;
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: step,
      getDrawingHorizontalLine: (_) => FlLine(color: color, strokeWidth: 1, dashArray: const [4, 4]),
    );
  }
}
