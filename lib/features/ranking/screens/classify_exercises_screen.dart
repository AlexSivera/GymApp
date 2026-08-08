import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/exercise_thumbnail.dart';
import '../../../services/progression_engine/estimated_one_rep_max.dart';
import '../providers/ranking_providers.dart';
import '../widgets/rank_badge.dart';

// One-at-a-time "reveal" flow for exercises that have enough history to be
// ranked but haven't been shown to the user yet. Snapshots the queue once
// on open so it doesn't shift underneath the user as they classify.
class ClassifyExercisesScreen extends ConsumerStatefulWidget {
  const ClassifyExercisesScreen({super.key});

  @override
  ConsumerState<ClassifyExercisesScreen> createState() => _ClassifyExercisesScreenState();
}

class _ClassifyExercisesScreenState extends ConsumerState<ClassifyExercisesScreen> {
  late final List<ExerciseRankInfo> _queue;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _queue = List.of(ref.read(unclassifiedExercisesProvider));
  }

  Future<void> _respond({required bool acknowledge}) async {
    final info = _queue[_index];
    if (acknowledge) {
      await ref
          .read(rankingDaoProvider)
          .acknowledge(info.exercise.id, info.rank.tier.index, info.rank.subTier);
    }
    if (_index + 1 >= _queue.length) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('Nada que clasificar todavía.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      );
    }

    final info = _queue[_index];
    final rank = info.rank;
    final rankColor = rankTierColors[rank.tier]!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_index + 1} de ${_queue.length}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.xs),
                child: LinearProgressIndicator(
                  value: _index / _queue.length,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.normal,
                  switchInCurve: AppMotion.curve,
                  child: KeyedSubtree(
                    key: ValueKey(info.exercise.id),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ExerciseThumbnail(imagePaths: info.exercise.imagePaths, size: 96),
                        const SizedBox(height: AppSpacing.lg),
                        Text(info.exercise.name,
                            style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.xxl),
                        RankBadge(rank: rank, size: 100),
                        const SizedBox(height: AppSpacing.md),
                        Text('RANGO ESTIMADO',
                            style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.5)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(rank.label,
                            style: theme.textTheme.headlineMedium?.copyWith(color: rankColor)),
                        const SizedBox(height: AppSpacing.xxl),
                        Row(
                          children: [
                            Expanded(
                              child: _StatBlock(
                                icon: Icons.fitness_center,
                                label: 'Mejor serie',
                                value:
                                    '${_fmt(info.bestSet.weightKg!)} kg × ${info.bestSet.reps}',
                              ),
                            ),
                            Expanded(
                              child: _StatBlock(
                                icon: Icons.show_chart,
                                label: '1RM estimado',
                                value:
                                    '${estimatedOneRepMax(info.bestSet.weightKg!, info.bestSet.reps!).round()} kg',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respond(acknowledge: false),
                      child: const Text('Saltar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _respond(acknowledge: true),
                      child: const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: theme.textTheme.titleMedium),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
