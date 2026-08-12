import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/weight_unit.dart';
import '../../../core/utils/weight_unit_provider.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../../core/widgets/exercise_thumbnail.dart';
import '../../../services/progression_engine/estimated_one_rep_max.dart';
import '../../../services/ranking_engine/compute_new_rank_achievements.dart';
import '../../../services/ranking_engine/strength_standards.dart';
import '../widgets/rank_badge.dart';
import '../widgets/rank_stat_block.dart';

// Celebratory reveal shown right after finishing a workout when it produced
// a new rank (first-time classification or a tier climb). Unlike the old
// manual classification queue, there's no "Saltar" here — these ranks are
// already earned and already persisted, this screen just shows them off.
class RankAchievementScreen extends ConsumerStatefulWidget {
  const RankAchievementScreen({super.key, required this.achievements});

  final List<RankAchievement> achievements;

  @override
  ConsumerState<RankAchievementScreen> createState() => _RankAchievementScreenState();
}

class _RankAchievementScreenState extends ConsumerState<RankAchievementScreen> {
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
    final unit = ref.watch(weightUnitProvider);
    final achievement = widget.achievements[_index];
    final rank = achievement.rank;
    final rankColor = rankTierColors[rank.tier]!;
    final previousRank = achievement.previousRank;
    final total = widget.achievements.length;

    return CelebrationOverlay(
      child: Scaffold(
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events_rounded, color: rankColor, size: 20),
                            const SizedBox(width: AppSpacing.xs),
                            Text(previousRank == null ? 'Nuevo rango' : '¡Subiste de rango!',
                                style: theme.textTheme.titleMedium),
                          ],
                        ),
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
                        if (exerciseStandards[achievement.exercise.name]?.baselineHoldSeconds != null)
                          RankStatBlock(
                            icon: Icons.timer_outlined,
                            label: 'Mejor serie',
                            value: _fmtSeconds(achievement.bestSet.durationSeconds!),
                          )
                        else if (exerciseStandards[achievement.exercise.name]?.baselineReps != null)
                          RankStatBlock(
                            icon: Icons.repeat,
                            label: 'Mejor serie',
                            value: '${achievement.bestSet.reps} reps',
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: RankStatBlock(
                                  icon: Icons.fitness_center,
                                  label: 'Mejor serie',
                                  value:
                                      '${formatWeightValue(achievement.bestSet.weightKg!, unit)} ${weightUnitLabel(unit)} × ${achievement.bestSet.reps}',
                                ),
                              ),
                              Expanded(
                                child: RankStatBlock(
                                  icon: Icons.show_chart,
                                  label: '1RM estimado',
                                  value: formatWeight(
                                      estimatedOneRepMax(
                                          achievement.bestSet.weightKg!, achievement.bestSet.reps!),
                                      unit,
                                      decimals: 0),
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
      ),
    );
  }
}

// "45s" / "2 min" — matches the format used elsewhere for isometric/cardio
// durations (session summary, live workout screen).
String _fmtSeconds(int seconds) {
  final minutes = seconds ~/ 60;
  return minutes > 0 ? '$minutes min' : '${seconds}s';
}
