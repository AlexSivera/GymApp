import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/exercise_thumbnail.dart';
import '../../../services/progression_engine/estimated_one_rep_max.dart';
import '../../../services/ranking_engine/compute_new_rank_achievements.dart';
import '../widgets/rank_badge.dart';
import '../widgets/rank_stat_block.dart';

// Celebratory reveal shown right after finishing a workout when it produced
// a new rank (first-time classification or a tier climb). Unlike the old
// manual classification queue, there's no "Saltar" here — these ranks are
// already earned and already persisted, this screen just shows them off.
class RankAchievementScreen extends StatefulWidget {
  const RankAchievementScreen({super.key, required this.achievements});

  final List<RankAchievement> achievements;

  @override
  State<RankAchievementScreen> createState() => _RankAchievementScreenState();
}

class _RankAchievementScreenState extends State<RankAchievementScreen> {
  int _index = 0;

  void _next() {
    if (_index + 1 >= widget.achievements.length) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final achievement = widget.achievements[_index];
    final rank = achievement.rank;
    final rankColor = rankTierColors[rank.tier]!;
    final previousRank = achievement.previousRank;
    final total = widget.achievements.length;

    return Scaffold(
      appBar: AppBar(title: Text(total > 1 ? '${_index + 1} de $total' : 'Nuevo rango')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            children: [
              if (total > 1)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                  child: LinearProgressIndicator(
                    value: _index / total,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.normal,
                  switchInCurve: AppMotion.curve,
                  child: KeyedSubtree(
                    key: ValueKey(achievement.exercise.id),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(previousRank == null ? '🎉 Nuevo rango' : '🎉 ¡Subiste de rango!',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.lg),
                        ExerciseThumbnail(imagePaths: achievement.exercise.imagePaths, size: 96),
                        const SizedBox(height: AppSpacing.md),
                        Text(achievement.exercise.name,
                            style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.xxl),
                        RankBadge(rank: rank, size: 100),
                        const SizedBox(height: AppSpacing.md),
                        if (previousRank != null)
                          Text(
                            previousRank.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(rank.label, style: theme.textTheme.headlineMedium?.copyWith(color: rankColor)),
                        const SizedBox(height: AppSpacing.xxl),
                        Row(
                          children: [
                            Expanded(
                              child: RankStatBlock(
                                icon: Icons.fitness_center,
                                label: 'Mejor serie',
                                value:
                                    '${_fmt(achievement.bestSet.weightKg!)} kg × ${achievement.bestSet.reps}',
                              ),
                            ),
                            Expanded(
                              child: RankStatBlock(
                                icon: Icons.show_chart,
                                label: '1RM estimado',
                                value:
                                    '${estimatedOneRepMax(achievement.bestSet.weightKg!, achievement.bestSet.reps!).round()} kg',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(_index + 1 >= total ? 'Continuar' : 'Siguiente'),
                ),
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
