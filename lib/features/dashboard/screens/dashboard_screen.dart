import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_retry_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/calories_today_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/hero_today_card.dart';
import '../widgets/insight_of_day_card.dart';
import '../widgets/next_session_card.dart';
import '../widgets/progress_card.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/streak_card.dart';
import '../widgets/weekly_goal_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysSession = ref.watch(todaysSessionProvider);
    final recentActivity = ref.watch(recentActivityProvider);
    final nextSession = ref.watch(nextPlannedSessionProvider);
    final streak = ref.watch(workoutStreakProvider);
    final caloriesToday = ref.watch(caloriesBurnedTodayProvider);
    final weeklyGoal = ref.watch(weeklyGoalProvider);
    final weeklySummary = ref.watch(weeklySummaryProvider);
    final insight = ref.watch(insightOfDayProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
          children: [
            const FadeSlideIn(index: 0, child: DashboardHeader()),
            const SizedBox(height: AppSpacing.lg),
            FadeSlideIn(
              index: 1,
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
            FadeSlideIn(
              index: 2,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: streak.when(
                        data: (value) => StreakCard(streak: value),
                        loading: () => const ShimmerBox(height: 150),
                        error: (e, _) => ErrorRetryCard(
                          message: 'No se ha podido cargar la racha.',
                          onRetry: () => ref.invalidate(workoutStreakProvider),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: caloriesToday.when(
                        data: (value) => CaloriesTodayCard(calories: value),
                        loading: () => const ShimmerBox(height: 150),
                        error: (e, _) => ErrorRetryCard(
                          message: 'No se han podido cargar las calorías.',
                          onRetry: () => ref.invalidate(caloriesBurnedTodayProvider),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(index: 3, child: WeeklyGoalCard(goal: weeklyGoal)),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(
              index: 4,
              child: weeklySummary.when(
                data: (summary) => ProgressCard(summary: summary),
                loading: () => const ShimmerBox(height: 140),
                error: (e, _) => ErrorRetryCard(
                  message: 'No se ha podido cargar tu progreso.',
                  onRetry: () => ref.invalidate(weeklySummaryProvider),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(
              index: 5,
              child: recentActivity.when(
                data: (sessions) => RecentActivityCard(sessions: sessions),
                loading: () => const ShimmerBox(height: 160),
                error: (e, _) => ErrorRetryCard(
                  message: 'No se ha podido cargar la actividad reciente.',
                  onRetry: () => ref.invalidate(recentActivityProvider),
                ),
              ),
            ),
            nextSession.whenOrNull(data: (session) {
                  if (session == null) return null;
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: FadeSlideIn(index: 6, child: NextSessionCard(session: session)),
                  );
                }) ??
                const SizedBox.shrink(),
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(
              index: 7,
              child: insight.when(
                data: (value) => InsightOfDayCard(message: value.message),
                loading: () => const ShimmerBox(height: 90),
                error: (e, _) => ErrorRetryCard(
                  message: 'No se ha podido cargar el consejo del día.',
                  onRetry: () => ref.invalidate(insightOfDayProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
