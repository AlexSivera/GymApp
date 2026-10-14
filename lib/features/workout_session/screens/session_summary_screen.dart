import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/set_format.dart';
import '../../../core/utils/weight_unit.dart';
import '../../../core/utils/weight_unit_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../../core/widgets/count_up_text.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../services/insights_engine/session_summary.dart';
import '../../../core/theme/z_palette.dart';
import '../../../services/z/z_sound.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../dashboard/providers/dashboard_scroll.dart';
import '../../../services/z/campaign.dart';
import '../../../services/z/episodes.dart';
import '../../../services/z/masters.dart';
import '../../../services/z/mentor_lines.dart';
import '../../z/providers/z_providers.dart';
import '../../z/screens/episode_screens.dart';
import '../../z/widgets/campaign_widgets.dart';
import '../../z/widgets/z_moments_watcher.dart';
import '../../z/widgets/z_visuals.dart';

class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({
    super.key,
    required this.summary,
    this.celebrate = false,
    this.justFinished = false,
    this.combat,
    this.extraHit = 0,
  });

  final SessionSummary summary;

  // Confetti only right after finishing a workout — not when reopening a
  // past one from Inicio/Calendario — and not when a rank-up screen is shown
  // on top first, since that one already throws its own.
  final bool celebrate;

  // Opened right after finishing (not reopened from history) — the only
  // time the "esfera conseguida" panel can apply.
  final bool justFinished;

  // This session's weekly combat (it completed the target), if any.
  final CampaignEvent? combat;
  // Advance damage on the next form from a session beyond the target.
  final double extraHit;

  // This screen is pushed imperatively on top of whichever tab's own
  // navigator was active (Inicio, Calendario o Entreno), and that navigator
  // keeps its stack when switching tabs. A plain pop — which is what both
  // the system/gesture back button and the AppBar's default back arrow do —
  // just reveals whatever was directly underneath. From the "just finished a
  // workout" path that's the /workout branch's own root screen, which by
  // now renders a blank placeholder (the session is no longer active), so
  // the user lands on an apparently-frozen black screen. Pop back to the
  // tab's root first, then switch to Inicio — every exit from this screen
  // must go through this, not a bare pop.
  void _goHome(BuildContext context, WidgetRef ref) {
    // Land on the top of Inicio (the hero card now says "completado"), not
    // wherever it was last scrolled to. Scheduled first, while this screen's
    // ref is certainly still alive.
    scrollDashboardToTop(ref);
    // Right after a combat: "¡En el próximo episodio!" first, then home.
    if (justFinished && ref.read(zStateValueProvider).episodesEnabled) {
      final text = nextEpisode(buildNextEpisodeInput(ref, combat: combat, extraHit: extraHit));
      final sagaSlot = ref.read(sagaProvider).mediaSlot;
      Navigator.of(context).push(NextEpisodeScreen.route(text, sagaSlot)).then((_) {
        if (!context.mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        context.go('/dashboard');
      });
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final unit = ref.watch(weightUnitProvider);
    final hasImprovements = summary.improvements.isNotEmpty;
    final hasPRs = summary.newPRs.isNotEmpty;
    final muted = theme.colorScheme.onSurfaceVariant;

    var index = 0;
    Widget reveal(Widget child) => FadeSlideIn(index: index++, child: child);

    // This workout is the one that completed the week's target: an esfera.
    final weekly = ref.watch(weeklyGoalProvider);
    final balls = ref.watch(dragonBallsProvider);
    final earnedBall = justFinished && weekly.completed == weekly.target && balls.count > 0;

    return CelebrationOverlay(
      play: celebrate,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _goHome(context, ref);
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Volver al inicio',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _goHome(context, ref),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
            children: [
              reveal(_MangaBurst(subtitle: summary.routineDayName)),
              if (extraHit > 0 && ref.watch(campaignProvider)?.current != null) ...[
                const SizedBox(height: AppSpacing.md),
                reveal(AppCard(
                  borderColor: ZColors.kaioken.withValues(alpha: 0.6),
                  child: Row(
                    children: [
                      VillainPortrait(fight: ref.watch(campaignProvider)!.current!, width: 48, height: 56),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GOLPE DE VENTAJA', style: theme.textTheme.labelMedium?.copyWith(color: ZColors.kaioken)),
                            Text(
                              '−${(extraHit * 100).round()} % a ${ref.watch(campaignProvider)!.current!.displayName} antes de su combate',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              if (earnedBall) ...[
                const SizedBox(height: AppSpacing.md),
                reveal(_EarnedBallPanel(stars: balls.count)),
              ],
              const SizedBox(height: AppSpacing.xl),
              reveal(AppCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      _Stat(
                        label: 'Duración',
                        child: Text(
                          summary.durationSeconds == null ? '—' : formatSessionDuration(summary.durationSeconds!),
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      VerticalDivider(color: colors.border, width: 1),
                      _Stat(
                        label: 'Series',
                        child: CountUpText(
                          value: summary.setsCompleted.toDouble(),
                          format: (v) => v.round().toString(),
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      VerticalDivider(color: colors.border, width: 1),
                      _Stat(
                        label: 'Volumen',
                        child: CountUpText(
                          value: kgToDisplayUnit(summary.volumeThisSession, unit),
                          format: (v) => '${v.round()}\u00A0${weightUnitLabel(unit)}',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      if (summary.caloriesBurned > 0) ...[
                        VerticalDivider(color: colors.border, width: 1),
                        _Stat(
                          label: 'Ki (kcal)',
                          child: CountUpText(
                            value: summary.caloriesBurned,
                            format: (v) => v.round().toString(),
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
              if (summary.volumeChangePercent != null) ...[
                const SizedBox(height: AppSpacing.sm),
                reveal(Text(
                  '${summary.volumeChangePercent! >= 0 ? '+' : ''}${summary.volumeChangePercent!.toStringAsFixed(0)}% de volumen vs la última vez con esta cápsula',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: summary.volumeChangePercent! >= 0 ? colors.statusCompleted : colors.statusSkipped,
                    fontWeight: FontWeight.w600,
                  ),
                )),
              ],
              if (hasPRs) ...[
                const SizedBox(height: AppSpacing.md),
                reveal(AppCard(
                  color: ZColors.mangaInk,
                  borderColor: ZColors.gold.withValues(alpha: 0.7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¡LÍMITE SUPERADO!', style: ZText.display(size: 22, color: ZColors.gold)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        summary.newPRs.length == 1 ? 'Nueva técnica dominada' : 'Nuevas técnicas dominadas',
                        style: theme.textTheme.bodySmall?.copyWith(color: ZColors.gold.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final name in summary.newPRs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(name, style: theme.textTheme.titleMedium),
                        ),
                      // Vegeta's cameo, once he's on your side.
                      if (justFinished && ref.watch(zStateValueProvider).unlockedMasterIds.contains('vegeta')) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MentorPortrait(master: masterById('vegeta'), mood: MentorMood.serio, size: 40),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(vegetaRecordCameo,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                )),
              ],
              if (hasImprovements) ...[
                const SizedBox(height: AppSpacing.md),
                reveal(AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Más fuerte que la última vez', style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      for (final improvement in summary.improvements)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            children: [
                              Icon(Icons.trending_up_rounded, size: 18, color: colors.statusCompleted),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(child: Text(improvement.exerciseName)),
                              Text(
                                improvement.message,
                                style: theme.textTheme.labelLarge?.copyWith(color: colors.statusCompleted),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                )),
              ],
              if (summary.exerciseLogs.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                reveal(AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
                        child: Text(
                          summary.exerciseLogs.length == 1
                              ? '1 técnica'
                              : '${summary.exerciseLogs.length} técnicas',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      for (var i = 0; i < summary.exerciseLogs.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(summary.exerciseLogs[i].exerciseName, style: theme.textTheme.bodyLarge),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Flexible(
                                child: Text(
                                  summary.exerciseLogs[i].setsSummary,
                                  textAlign: TextAlign.end,
                                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i != summary.exerciseLogs.length - 1)
                          const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ),
                )),
              ],
              if (!hasImprovements && !hasPRs) ...[
                const SizedBox(height: AppSpacing.md),
                reveal(AppCard(
                  child: Text(
                    'Kaio-sama ha tomado nota. El próximo entrenamiento se medirá contra este.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                )),
              ],
              const SizedBox(height: AppSpacing.xl),
              reveal(SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _goHome(context, ref),
                  child: const Text('Volver a la Kame House'),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// The one manga moment of the app: paper, ink and focus lines.
class _MangaBurst extends StatelessWidget {
  const _MangaBurst({required this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: ZColors.mangaPaper,
        border: Border.all(color: ZColors.mangaInk, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: SpeedLines(color: ZColors.mangaInk, focus: Alignment.center, opacity: 0.55)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: -0.06,
                child: Stack(
                  children: [
                    Text(
                      '¡ENTRENAMIENTO\nTERMINADO!',
                      textAlign: TextAlign.center,
                      style: ZText.display(size: 26, height: 0.95).copyWith(
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 5
                          ..color = ZColors.mangaInk,
                      ),
                    ),
                    Text(
                      '¡ENTRENAMIENTO\nTERMINADO!',
                      textAlign: TextAlign.center,
                      style: ZText.display(size: 26, height: 0.95, color: ZColors.gi),
                    ),
                  ],
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  color: ZColors.mangaPaper,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(subtitle!.toUpperCase(), style: ZText.hud(size: 12, color: ZColors.mangaInk)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EarnedBallPanel extends StatefulWidget {
  const _EarnedBallPanel({required this.stars});

  final int stars;

  @override
  State<_EarnedBallPanel> createState() => _EarnedBallPanelState();
}

class _EarnedBallPanelState extends State<_EarnedBallPanel> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      ZSound.play('dragon_ball');
      ZHaptics.hit();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      borderColor: ZColors.ball.withValues(alpha: 0.7),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: DragonBall(stars: widget.stars, size: 52, glow: true),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SEMANA CUMPLIDA', style: theme.textTheme.labelMedium?.copyWith(color: ZColors.ball)),
                const SizedBox(height: 2),
                Text('¡Esfera de ${widget.stars} ${widget.stars == 1 ? 'estrella' : 'estrellas'}!',
                    style: theme.textTheme.titleLarge),
                if (widget.stars >= 7)
                  Text('Ya puedes invocar a Shenlong desde la Kame House.',
                      style: theme.textTheme.bodySmall?.copyWith(color: ZColors.namek)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(fit: BoxFit.scaleDown, child: child),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.labelMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
