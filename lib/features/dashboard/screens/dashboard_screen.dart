import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/hero_today_card.dart';
import '../widgets/insight_of_day_card.dart';
import '../widgets/last_session_card.dart';
import '../widgets/next_session_card.dart';
import '../widgets/stat_tile.dart';
import '../widgets/weekly_goal_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysSession = ref.watch(todaysSessionProvider);
    final lastSession = ref.watch(lastCompletedSessionProvider);
    final nextSession = ref.watch(nextPlannedSessionProvider);
    final bodyWeight = ref.watch(latestBodyWeightProvider);
    final streak = ref.watch(workoutStreakProvider);
    final totalWorkouts = ref.watch(totalWorkoutsCompletedProvider);
    final caloriesToday = ref.watch(caloriesBurnedTodayProvider);
    final weeklyGoal = ref.watch(weeklyGoalProvider);
    final insight = ref.watch(insightOfDayProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_capitalize(DateFormat('EEEE d MMMM', 'es').format(DateTime.now()))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FadeSlideIn(
            index: 0,
            child: todaysSession.when(
              data: (session) => HeroTodayCard(session: session),
              loading: () => const _CardPlaceholder(),
              error: (e, _) => _CardError(message: '$e'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            index: 1,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: streak.when(
                        data: (value) => StatTile(
                          icon: Icons.local_fire_department_outlined,
                          label: 'Racha',
                          value: '$value',
                        ),
                        loading: () => const _CardPlaceholder(),
                        error: (e, _) => _CardError(message: '$e'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: bodyWeight.when(
                        data: (log) => StatTile(
                          icon: Icons.monitor_weight_outlined,
                          label: 'Peso corporal',
                          value: log == null ? '—' : '${log.weightKg} kg',
                        ),
                        loading: () => const _CardPlaceholder(),
                        error: (e, _) => _CardError(message: '$e'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: totalWorkouts.when(
                        data: (value) => StatTile(
                          icon: Icons.fitness_center_outlined,
                          label: 'Entrenamientos',
                          value: '$value',
                        ),
                        loading: () => const _CardPlaceholder(),
                        error: (e, _) => _CardError(message: '$e'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: caloriesToday.when(
                        data: (value) => StatTile(
                          icon: Icons.local_fire_department,
                          label: 'Calorías hoy',
                          value: value <= 0 ? '—' : '${value.round()} kcal',
                        ),
                        loading: () => const _CardPlaceholder(),
                        error: (e, _) => _CardError(message: '$e'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(index: 2, child: WeeklyGoalCard(goal: weeklyGoal)),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            index: 3,
            child: lastSession.when(
              data: (session) => LastSessionCard(session: session),
              loading: () => const _CardPlaceholder(),
              error: (e, _) => _CardError(message: '$e'),
            ),
          ),
          nextSession.whenOrNull(data: (session) {
                if (session == null) return null;
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: FadeSlideIn(index: 4, child: NextSessionCard(session: session)),
                );
              }) ??
              const SizedBox.shrink(),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            index: 5,
            child: insight.when(
              data: (value) => InsightOfDayCard(message: value.message),
              loading: () => const _CardPlaceholder(),
              error: (e, _) => _CardError(message: '$e'),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 96,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _CardError extends StatelessWidget {
  const _CardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error));
  }
}
