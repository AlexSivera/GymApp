import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_providers.dart';
import '../widgets/last_session_card.dart';
import '../widgets/stat_tile.dart';
import '../widgets/today_session_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysSession = ref.watch(todaysSessionProvider);
    final lastSession = ref.watch(lastCompletedSessionProvider);
    final bodyWeight = ref.watch(latestBodyWeightProvider);
    final streak = ref.watch(workoutStreakProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE d MMMM', 'es').format(DateTime.now())),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          todaysSession.when(
            data: (session) => TodaySessionCard(session: session),
            loading: () => const _CardPlaceholder(),
            error: (e, _) => _CardError(message: '$e'),
          ),
          const SizedBox(height: 12),
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 12),
          lastSession.when(
            data: (session) => LastSessionCard(session: session),
            loading: () => const _CardPlaceholder(),
            error: (e, _) => _CardError(message: '$e'),
          ),
        ],
      ),
    );
  }
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
