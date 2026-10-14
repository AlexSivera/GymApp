import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/z_palette.dart';
import '../../../core/utils/set_format.dart';
import '../../../core/utils/weight_unit.dart';
import '../../../core/utils/weight_unit_provider.dart';
import '../../../core/widgets/exercise_thumbnail.dart';
import '../../../services/progression_engine/estimated_one_rep_max.dart';
import '../../../services/ranking_engine/compute_new_rank_achievements.dart';
import '../../../services/ranking_engine/rank_tier.dart';
import '../../../services/ranking_engine/strength_standards.dart';
import '../../../services/z/z_sound.dart';
import '../../../services/z/masters.dart';
import '../../../services/z/mentor_lines.dart';
import '../../z/providers/z_providers.dart';
import '../../z/widgets/campaign_widgets.dart';
import '../../z/widgets/z_media.dart';
import '../../z/widgets/z_visuals.dart';
import '../widgets/rank_badge.dart';
import '../widgets/rank_stat_block.dart';

// ¡Transformación!: shown right after finishing a workout when it produced a
// new rank. A jump to a new form (tier) is the full transformation — the
// pack's clip for that form (or the generic one, or the stock photo) behind
// a burst of aura; a grade within the same form is a smaller "¡Más poder!".
// No "Saltar": these ranks are already earned and persisted, this screen
// just shows them off.
class RankAchievementScreen extends ConsumerStatefulWidget {
  const RankAchievementScreen({super.key, required this.achievements});

  final List<RankAchievement> achievements;

  @override
  ConsumerState<RankAchievementScreen> createState() => _RankAchievementScreenState();
}

class _RankAchievementScreenState extends ConsumerState<RankAchievementScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _burst =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  bool _isTransformation(RankAchievement a) => a.previousRank == null || a.previousRank!.tier != a.rank.tier;

  void _play() {
    if (!mounted) return;
    final achievement = widget.achievements[_index];
    if (MediaQuery.of(context).disableAnimations) {
      _burst.value = 1;
    } else {
      _burst.forward(from: 0);
    }
    ZSound.play(_isTransformation(achievement) ? 'transform' : 'level_up');
    ZHaptics.boom();
  }

  void _next() {
    if (_index + 1 >= widget.achievements.length) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
    _play();
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);
    final achievement = widget.achievements[_index];
    final rank = achievement.rank;
    final color = rankTierColors[rank.tier]!;
    final previous = achievement.previousRank;
    final total = widget.achievements.length;
    final transformation = _isTransformation(achievement);
    final standard = exerciseStandards[achievement.exercise.name];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ZMomentBackground(
            key: ValueKey('bg-$_index'),
            slots: ['transform_${rank.tier.slug}', 'transform'],
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.1,
                colors: [
                  color.withValues(alpha: transformation ? 0.35 : 0.2),
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0, 0.6, 1],
              ),
            ),
          ),
          // The scene stays bright up top; the texts below sit on darkness.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x26000000), Color(0xC7000000), Color(0xE6000000)],
                stops: [0, 0.3, 0.5, 1],
              ),
            ),
          ),
          if (transformation) SpeedLines(color: color, focus: const Alignment(0, -0.25), opacity: 0.22),
          Align(
            alignment: const Alignment(0, -0.35),
            child: Text('超', style: ZText.display(size: 240, color: color.withValues(alpha: 0.07))),
          ),
          SafeArea(
            child: FitOrScroll(child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              child: AnimatedBuilder(
                animation: _burst,
                builder: (context, _) {
                  final t = _burst.value;
                  final grow = Curves.elasticOut.transform((t / 0.6).clamp(0.0, 1.0));
                  final text = Curves.easeOutCubic.transform(((t - 0.35) / 0.4).clamp(0.0, 1.0));
                  return Column(
                    children: [
                      if (total > 1)
                        Text('${_index + 1} DE $total', style: ZText.hud(size: 12, color: color)),
                      const Spacer(),
                      Transform.scale(
                        scale: 0.6 + 0.4 * grow,
                        child: KiAura(
                          color: color,
                          intensity: rank.subTier / 3 + (transformation ? 0.4 : 0),
                          spread: 2.2,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: ExerciseThumbnail(imagePaths: achievement.exercise.imagePaths, size: 120),
                              ),
                              Positioned(right: -18, bottom: -18, child: RankBadge(rank: rank, size: 56)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl + AppSpacing.md),
                      Opacity(
                        opacity: text,
                        child: Transform.translate(
                          offset: Offset(0, 24 * (1 - text)),
                          child: Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  transformation ? '¡TRANSFORMACIÓN!' : '¡MÁS PODER!',
                                  maxLines: 1,
                                  style: ZText.display(size: 30, color: Colors.white).copyWith(
                                    shadows: [Shadow(color: color, blurRadius: 18), Shadow(color: color, blurRadius: 4)],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text.rich(
                                TextSpan(children: [
                                  TextSpan(
                                      text: achievement.exercise.name,
                                      style: const TextStyle(fontWeight: FontWeight.w800)),
                                  TextSpan(text: previous == null ? ' despierta en ' : ' alcanza '),
                                  TextSpan(
                                      text: rank.label,
                                      style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                                ]),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
                              ),
                              if (previous != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${previous.label.toUpperCase()}  →  ${rank.label.toUpperCase()}',
                                  textAlign: TextAlign.center,
                                  style: ZText.hud(size: 11, color: Colors.white70),
                                ),
                              ],
                              // Goku's cameo, once he's on your side.
                              if (transformation && ref.watch(zStateValueProvider).unlockedMasterIds.contains('goku')) ...[
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    MentorPortrait(master: masterById('goku'), mood: MentorMood.riendo, size: 36),
                                    const SizedBox(width: AppSpacing.sm),
                                    Flexible(
                                      child: Text(gokuTransformCameo,
                                          style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic)),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Opacity(
                        opacity: text,
                        child: DefaultTextStyle.merge(
                          style: const TextStyle(color: Colors.white),
                          child: standard?.baselineHoldSeconds != null
                              ? RankStatBlock(
                                  icon: Icons.timer_outlined,
                                  label: 'Mejor serie',
                                  value: _fmtSeconds(achievement.bestSet.durationSeconds!),
                                )
                              : standard?.baselineReps != null
                                  ? RankStatBlock(
                                      icon: Icons.repeat,
                                      label: 'Mejor serie',
                                      value: '${achievement.bestSet.reps} reps',
                                    )
                                  : Row(
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
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: ZColors.night),
                          onPressed: _next,
                          child: Text(_index + 1 >= total ? 'Seguir' : 'Siguiente'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            )),
          ),
          // White flash at the instant of the transformation.
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _burst,
              builder: (context, _) {
                final flash = transformation ? (1 - (_burst.value / 0.18)).clamp(0.0, 1.0) : 0.0;
                return ColoredBox(color: Colors.white.withValues(alpha: 0.85 * flash * (_burst.value > 0 ? 1 : 0)));
              },
            ),
          ),
        ],
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
