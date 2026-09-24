import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/set_format.dart';
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
                        _RankReveal(
                          badge: RankBadge(rank: rank, size: 100),
                          color: rankColor,
                          previousLabel: previousRank?.label,
                          label: rank.label,
                        ),
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
                                  value: formatStrengthSet(
                                      achievement.bestSet.weightKg!, achievement.bestSet.reps!, unit),
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

// The moment the new rank lands, staged instead of all at once: a glow
// blooms behind the badge, the badge pops in with a little overshoot, the old
// rank (if any) is struck out and the new one rises into place. With
// "reduce motion" on it all just appears.
class _RankReveal extends StatefulWidget {
  const _RankReveal({
    required this.badge,
    required this.color,
    required this.previousLabel,
    required this.label,
  });

  final Widget badge;
  final Color color;
  final String? previousLabel;
  final String label;

  @override
  State<_RankReveal> createState() => _RankRevealState();
}

class _RankRevealState extends State<_RankReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.value > 0) return;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end, Curve curve) =>
      CurvedAnimation(parent: _controller, curve: Interval(begin, end, curve: curve));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glow = _interval(0.0, 0.45, Curves.easeOut);
    final badgeScale = _interval(0.1, 0.55, Curves.elasticOut);
    final badgeFade = _interval(0.1, 0.25, Curves.easeOut);
    final strike = _interval(0.45, 0.65, Curves.easeInOut);
    final newLabel = _interval(0.55, 0.85, Curves.easeOutCubic);

    return Column(
      children: [
        SizedBox(
          width: 170,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: glow,
                builder: (context, _) => Container(
                  width: 90 + 80 * glow.value,
                  height: 90 + 80 * glow.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      widget.color.withValues(alpha: 0.35 * glow.value),
                      widget.color.withValues(alpha: 0),
                    ]),
                  ),
                ),
              ),
              FadeTransition(
                opacity: badgeFade,
                child: ScaleTransition(scale: badgeScale, child: widget.badge),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (widget.previousLabel != null)
          AnimatedBuilder(
            animation: strike,
            builder: (context, _) => Opacity(
              opacity: 1 - 0.45 * strike.value,
              child: CustomPaint(
                foregroundPainter: _StrikePainter(
                  progress: strike.value,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                child: Text(
                  widget.previousLabel!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
        FadeTransition(
          opacity: newLabel,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(newLabel),
            child: Text(widget.label, style: theme.textTheme.headlineMedium?.copyWith(color: widget.color)),
          ),
        ),
      ],
    );
  }
}

class _StrikePainter extends CustomPainter {
  const _StrikePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final y = size.height * 0.55;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width * progress, y),
      Paint()
        ..color = color
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// "45s" / "2 min" — matches the format used elsewhere for isometric/cardio
// durations (session summary, live workout screen).
String _fmtSeconds(int seconds) {
  final minutes = seconds ~/ 60;
  return minutes > 0 ? '$minutes min' : '${seconds}s';
}
