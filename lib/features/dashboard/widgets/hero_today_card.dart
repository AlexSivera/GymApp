import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../router/workout_branch_navigator_key.dart';
import '../../../services/workout_session/start_session.dart';
import '../../routines/providers/routines_providers.dart';
import '../../routines/widgets/routine_day_picker_sheet.dart';

class HeroTodayCard extends ConsumerWidget {
  const HeroTodayCard({super.key, required this.session});

  final WorkoutSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRoutines = ref.watch(routinesListProvider).valueOrNull?.isNotEmpty ?? true;
    return AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.curve,
      switchOutCurve: AppMotion.curve,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(
        key: ValueKey('${session?.id}-${session?.status}-${session?.routineDayId}-$hasRoutines'),
        child: _buildContent(context, ref),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = this.session;

    if (session == null || session.status == SessionStatus.rest) {
      final hasNoRoutines =
          session == null && (ref.watch(routinesListProvider).valueOrNull?.isEmpty ?? false);

      if (hasNoRoutines) {
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('👋 Primeros pasos', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('Crea tu primera rutina para empezar a entrenar.',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/calendar'),
                  child: const Text('Crear rutina'),
                ),
              ),
            ],
          ),
        );
      }

      final isRest = session?.status == SessionStatus.rest;
      return AppCard(
        color: isRest ? AppTheme.statusRest.withValues(alpha: 0.08) : null,
        borderColor: isRest ? AppTheme.statusRest.withValues(alpha: 0.35) : null,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hoy', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isRest ? 'Hoy es tu día de descanso.' : 'No tienes ningún entrenamiento programado.',
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
      final stateColor =
          session.status == SessionStatus.completed ? AppTheme.statusCompleted : AppTheme.statusSkipped;
      return AppCard(
        color: stateColor.withValues(alpha: 0.08),
        borderColor: stateColor.withValues(alpha: 0.35),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: stateColor.withValues(alpha: 0.18), shape: BoxShape.circle),
                  child: Icon(
                    session.status == SessionStatus.completed
                        ? Icons.check_circle
                        : Icons.remove_circle_outline,
                    color: stateColor,
                  ),
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
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _startAnotherSession(context, ref),
                child: const Text('+ Añadir otro entrenamiento'),
              ),
            ),
          ],
        ),
      );
    }

    // planned or inProgress with a routine attached.
    final dayName = ref.watch(routineDaySessionTitleProvider(session.routineDayId)) ?? 'Entrenamiento libre';
    final hasTimeOfDay = session.date.hour != 0 || session.date.minute != 0;

    return AppCard(
      color: AppTheme.accent.withValues(alpha: 0.08),
      borderColor: AppTheme.accent.withValues(alpha: 0.35),
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
    if (context.mounted) goToFreshWorkout(context);
  }

  // For people who train more than once a day: today already has a
  // completed/skipped session, so this starts a second one right now rather
  // than going through the "planned for later" state.
  Future<void> _startAnotherSession(BuildContext context, WidgetRef ref) async {
    final day = await showRoutineDayPicker(context);
    if (day == null) return;

    final db = ref.read(appDatabaseProvider);
    await startSessionFromRoutineDay(db, routineDayId: day.id, date: DateTime.now());
    if (context.mounted) goToFreshWorkout(context);
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
