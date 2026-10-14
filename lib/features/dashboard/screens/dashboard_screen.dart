import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/z_palette.dart';
import '../../../core/widgets/error_retry_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/notifications/reminder_scheduler.dart';
import '../../z/providers/z_providers.dart';
import '../../z/widgets/campaign_widgets.dart';
import '../../z/widgets/kame_house_cards.dart';
import '../../z/widgets/z_moments_watcher.dart';
import '../../z/widgets/over_9000.dart';
import '../../z/screens/general_transformation_screen.dart';
import '../../z/widgets/z_media.dart';
import '../providers/dashboard_providers.dart';
import '../providers/dashboard_scroll.dart';
import '../widgets/calories_today_card.dart';
import '../widgets/hero_today_card.dart';
import '../widgets/next_session_card.dart';
import '../widgets/recent_activity_card.dart';

// La Kame House: the scouter reading, today's training, the esferas and the
// Genkidama of the week, and Kaio-sama's tip — under the sky of the saga
// the user is in.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Today's session status (planned/completed/skipped) and the streak both
    // feed the "hoy toca entrenar" / "racha en riesgo" reminders — re-checking
    // whenever either changes means finishing a workout silences today's
    // reminder immediately instead of it firing anyway later.
    ref.listen(todaysSessionProvider, (_, _) {
      refreshDailyReminders(ref.read(appDatabaseProvider));
    });
    ref.listen(workoutStreakProvider, (_, _) {
      refreshDailyReminders(ref.read(appDatabaseProvider));
    });
    final todaysSession = ref.watch(todaysSessionProvider);
    final recentActivity = ref.watch(recentActivityProvider);
    final nextSession = ref.watch(nextPlannedSessionProvider);
    final caloriesToday = ref.watch(caloriesBurnedTodayProvider);
    final insight = ref.watch(insightOfDayProvider);
    final saga = ref.watch(sagaProvider);

    return Scaffold(
      body: Stack(
        children: [
          // The saga's sky behind the top of the screen, fading into the
          // night background.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 360,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.transparent],
                stops: [0.55, 1],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Opacity(opacity: 0.9, child: ZImage(saga.mediaSlot)),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 360,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ZColors.night.withValues(alpha: 0.35), ZColors.night.withValues(alpha: 0.05), ZColors.night.withValues(alpha: 0.6)],
                    stops: const [0, 0.3, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              controller: ref.watch(dashboardScrollControllerProvider),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
              children: [
                const GeneralTransformationWatcher(),
                const Over9000Watcher(),
                const ZMomentsWatcher(),
                const FadeSlideIn(index: 0, child: KameHouseHeader()),
                // Leaves the saga scene visible above the cards.
                const SizedBox(height: 150),
                const FadeSlideIn(index: 1, child: PowerLevelCard()),
                const SizedBox(height: AppSpacing.md),
                FadeSlideIn(
                  index: 2,
                  child: todaysSession.when(
                    data: (session) => HeroTodayCard(session: session),
                    loading: () => const ShimmerBox(height: 190),
                    error: (e, _) => ErrorRetryCard(
                      message: 'No se ha podido cargar el entrenamiento de hoy.',
                      onRetry: () => ref.invalidate(todaysSessionProvider),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const FadeSlideIn(index: 3, child: BossWeekCard()),
                const SizedBox(height: AppSpacing.md),
                const FadeSlideIn(index: 3, child: DragonBallsCard()),
                const SizedBox(height: AppSpacing.md),
                FadeSlideIn(
                  index: 4,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(flex: 3, child: GenkidamaCard()),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 2,
                          child: caloriesToday.when(
                            data: (value) => CaloriesTodayCard(calories: value),
                            loading: () => const ShimmerBox(height: 150),
                            error: (e, _) => ErrorRetryCard(
                              message: 'No se ha podido cargar el ki gastado.',
                              onRetry: () => ref.invalidate(caloriesBurnedTodayProvider),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeSlideIn(
                  index: 5,
                  child: insight.when(
                    data: (value) => MentorPeekCard(insight: value),
                    loading: () => const ShimmerBox(height: 90),
                    error: (e, _) => ErrorRetryCard(
                      message: 'Tu maestro no responde. Prueba otra vez.',
                      onRetry: () => ref.invalidate(insightOfDayProvider),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeSlideIn(
                  index: 6,
                  child: recentActivity.when(
                    data: (sessions) => RecentActivityCard(sessions: sessions),
                    loading: () => const ShimmerBox(height: 160),
                    error: (e, _) => ErrorRetryCard(
                      message: 'No se han podido cargar tus últimos entrenamientos.',
                      onRetry: () => ref.invalidate(recentActivityProvider),
                    ),
                  ),
                ),
                nextSession.whenOrNull(data: (session) {
                      if (session == null) return null;
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: FadeSlideIn(index: 7, child: NextSessionCard(session: session)),
                      );
                    }) ??
                    const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
