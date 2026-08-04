import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/workout_session/start_session.dart';
import '../../routines/providers/routines_providers.dart';
import '../../routines/widgets/routine_day_picker_sheet.dart';

class HeroTodayCard extends ConsumerWidget {
  const HeroTodayCard({super.key, required this.session});

  final WorkoutSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = this.session;

    if (session == null || session.status == SessionStatus.rest) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hoy', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              session?.status == SessionStatus.rest
                  ? 'Hoy es tu día de descanso.'
                  : 'No tienes ningún entrenamiento programado.',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (session?.status != SessionStatus.rest)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _pickRoutine(context, ref, existingSession: null),
                  child: const Text('Elegir rutina'),
                ),
              ),
          ],
        ),
      );
    }

    if (session.status == SessionStatus.completed || session.status == SessionStatus.skipped) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            Icon(
              session.status == SessionStatus.completed ? Icons.check_circle : Icons.remove_circle_outline,
              color: session.status == SessionStatus.completed
                  ? AppTheme.statusCompleted
                  : AppTheme.statusSkipped,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                session.status == SessionStatus.completed
                    ? 'Ya has entrenado hoy. ¡Buen trabajo!'
                    : 'Hoy se marcó como entrenamiento saltado.',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
      );
    }

    // planned or inProgress with a routine attached.
    final dayAsync =
        session.routineDayId != null ? ref.watch(routineDayByIdProvider(session.routineDayId!)) : null;
    final dayName = dayAsync?.valueOrNull?.name ?? 'Entrenamiento libre';
    final hasTimeOfDay = session.date.hour != 0 || session.date.minute != 0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hoy', style: theme.textTheme.labelMedium),
              if (session.status == SessionStatus.planned)
                TextButton(
                  onPressed: () => _pickRoutine(context, ref, existingSession: session),
                  child: const Text('Cambiar rutina'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(dayName, style: theme.textTheme.displaySmall),
          if (hasTimeOfDay) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(DateFormat('HH:mm').format(session.date),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: session.status == SessionStatus.inProgress
                  ? () => context.go('/workout')
                  : () => _startSession(context, ref, session),
              child: Text(session.status == SessionStatus.inProgress
                  ? 'CONTINUAR ENTRENAMIENTO'
                  : 'EMPEZAR ENTRENAMIENTO'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession(BuildContext context, WidgetRef ref, WorkoutSession session) async {
    final db = ref.read(appDatabaseProvider);
    await startPlannedSession(db, session: session);
    if (context.mounted) context.go('/workout');
  }

  Future<void> _pickRoutine(
    BuildContext context,
    WidgetRef ref, {
    required WorkoutSession? existingSession,
  }) async {
    final day = await showRoutineDayPicker(context);
    if (day == null) return;

    final db = ref.read(appDatabaseProvider);
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);

    if (existingSession != null) {
      await db.workoutSessionsDao.updateSession(
        existingSession.copyWith(routineDayId: Value(day.id)),
      );
    } else {
      await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
        date: date,
        routineDayId: Value(day.id),
        status: const Value(SessionStatus.planned),
      ));
    }
  }
}
