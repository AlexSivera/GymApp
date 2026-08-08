import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../services/progression_engine/estimated_one_rep_max.dart';
import '../../progress/providers/progress_providers.dart';
import '../../progress/widgets/exercise_progress_summary.dart';
import '../providers/ranking_providers.dart';
import '../widgets/rank_badge.dart';
import '../widgets/rank_stat_block.dart';

// Tapped from a muscle's exercise list in Rangos. Three tabs: current rank
// (Rango), the classic weight/1RM progress view (Resumen), and a session-by-
// session set log (Historial).
class ExerciseRankDetailScreen extends StatelessWidget {
  const ExerciseRankDetailScreen({super.key, required this.exerciseId, required this.exerciseName});

  final int exerciseId;
  final String exerciseName;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(exerciseName),
          bottom: const TabBar(tabs: [Tab(text: 'Rango'), Tab(text: 'Resumen'), Tab(text: 'Historial')]),
        ),
        body: TabBarView(
          children: [
            _RankTab(exerciseId: exerciseId),
            ExerciseProgressSummary(exerciseId: exerciseId),
            _HistoryTab(exerciseId: exerciseId),
          ],
        ),
      ),
    );
  }
}

class _RankTab extends ConsumerWidget {
  const _RankTab({required this.exerciseId});

  final int exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detail = ref.watch(exerciseRankDetailProvider(exerciseId));

    if (detail == null) {
      return Center(
        child: Text(
          'Todavía no tienes datos de este ejercicio.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final rank = detail.info.rank;
    final bestSet = detail.info.bestSet;
    final rankColor = rankTierColors[rank.tier]!;
    final next = detail.next;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: Column(
            children: [
              RankBadge(rank: rank, size: 120),
              const SizedBox(height: AppSpacing.md),
              Text(rank.label, style: theme.textTheme.headlineMedium?.copyWith(color: rankColor)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: RankStatBlock(
                  icon: Icons.fitness_center,
                  label: 'Mejor serie',
                  value: '${_fmt(bestSet.weightKg!)} kg × ${bestSet.reps}',
                ),
              ),
              Expanded(
                child: RankStatBlock(
                  icon: Icons.show_chart,
                  label: '1RM estimado',
                  value: '${estimatedOneRepMax(bestSet.weightKg!, bestSet.reps!).round()} kg',
                ),
              ),
            ],
          ),
        ),
        if (next != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SIGUIENTE RANGO',
                    style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.5)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    RankBadge(rank: next.rank, size: 32),
                    const SizedBox(width: AppSpacing.sm),
                    Text(next.rank.label,
                        style: theme.textTheme.titleMedium?.copyWith(color: rankTierColors[next.rank.tier])),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Estimación de la serie que te haría subir: ${_fmt(next.weightKg)} kg × ${bestSet.reps}',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _fmt(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.exerciseId});

  final int exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseId));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(
            child: Text(
              'Todavía no tienes entrenamientos registrados de este ejercicio.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: sessions.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final session = sessions[index];
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.routineName ?? 'Entrenamiento libre', style: theme.textTheme.titleMedium),
                  Text(
                    DateFormat("d 'de' MMMM 'de' y, HH:mm", 'es').format(session.date),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Serie',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ),
                      Expanded(
                        child: Text('Kg',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ),
                      Expanded(
                        child: Text('Reps',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                  for (final set in session.sets)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Row(
                        children: [
                          Expanded(child: Text('${set.setNumber}')),
                          Expanded(child: Text(_fmt(set.weightKg!))),
                          Expanded(child: Text('${set.reps}')),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _fmt(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}
