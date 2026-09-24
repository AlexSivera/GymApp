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
import '../../dashboard/providers/dashboard_scroll.dart';

class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({super.key, required this.summary, this.celebrate = false});

  final SessionSummary summary;

  // Confetti only right after finishing a workout — not when reopening a
  // past one from Inicio/Calendario — and not when a rank-up screen is shown
  // on top first, since that one already throws its own.
  final bool celebrate;

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
              reveal(Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.statusCompleted.withValues(alpha: 0.16),
                    ),
                    child: Icon(Icons.check_rounded, color: colors.statusCompleted, size: 36),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('¡Entrenamiento completado!',
                      style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                  if (summary.routineDayName != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(summary.routineDayName!,
                        style: theme.textTheme.bodyLarge?.copyWith(color: muted), textAlign: TextAlign.center),
                  ],
                ],
              )),
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
                          label: 'kcal (est.)',
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
                  '${summary.volumeChangePercent! >= 0 ? '+' : ''}${summary.volumeChangePercent!.toStringAsFixed(0)}% de volumen vs la última vez con esta rutina',
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
                  borderColor: colors.statusPlanned.withValues(alpha: 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emoji_events_rounded, size: 20, color: colors.statusPlanned),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            summary.newPRs.length == 1 ? 'Nuevo récord personal' : 'Nuevos récords personales',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final name in summary.newPRs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(name, style: theme.textTheme.bodyMedium),
                        ),
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
                      Text('Mejoras', style: theme.textTheme.titleMedium),
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
                              ? '1 ejercicio'
                              : '${summary.exerciseLogs.length} ejercicios',
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
                    'Sigue así — la próxima vez podrás comparar con esta sesión.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                )),
              ],
              const SizedBox(height: AppSpacing.xl),
              reveal(SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _goHome(context, ref),
                  child: const Text('Volver al inicio'),
                ),
              )),
            ],
          ),
        ),
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
