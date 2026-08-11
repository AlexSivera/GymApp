import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_duration.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../router/workout_branch_navigator_key.dart';
import '../../../services/insights_engine/session_summary.dart';
import '../../../services/workout_session/start_session.dart';
import '../../exercise_library/providers/exercise_library_providers.dart';
import '../../routines/providers/routines_providers.dart';
import '../../routines/widgets/routine_day_picker_sheet.dart';
import '../../workout_session/screens/session_summary_screen.dart';
import '../providers/dashboard_providers.dart';

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
              Text('👋 PRIMEROS PASOS',
                  style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.6)),
              const SizedBox(height: AppSpacing.sm),
              Text('Crea tu primera rutina para empezar a entrenar.',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/calendar'),
                  child: const Text('CREAR RUTINA'),
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
            Text('TU ENTRENAMIENTO DE HOY',
                style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.6)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isRest ? 'Hoy es tu día de descanso.' : 'No tienes ningún entrenamiento programado.',
              style: theme.textTheme.headlineMedium,
            ),
            if (!isRest) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _pickRoutine(context, ref, existingSession: null),
                  child: const Text('ELEGIR RUTINA →'),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (session.status == SessionStatus.completed || session.status == SessionStatus.skipped) {
      final isCompleted = session.status == SessionStatus.completed;
      final stateColor = isCompleted ? AppTheme.statusCompleted : AppTheme.statusSkipped;
      final dayName = ref.watch(routineDaySessionTitleProvider(session.routineDayId)) ?? 'Entrenamiento libre';
      final exerciseCount = ref.watch(sessionExerciseCountProvider(session.id)).valueOrNull;
      final duration = session.durationSeconds;

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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: stateColor.withValues(alpha: 0.18), shape: BoxShape.circle),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.remove_circle_outline,
                    color: stateColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    isCompleted ? 'ENTRENAMIENTO COMPLETADO' : 'ENTRENAMIENTO SALTADO',
                    style: theme.textTheme.labelMedium?.copyWith(color: stateColor, letterSpacing: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(dayName, style: theme.textTheme.headlineMedium),
            if (isCompleted && (duration != null || exerciseCount != null)) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                [
                  if (duration != null) formatWorkoutDuration(duration),
                  if (exerciseCount != null) '$exerciseCount ejercicios',
                ].join(' · '),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (isCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _viewSession(context, ref, session),
                  child: const Text('VER ENTRENAMIENTO →'),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.only(top: isCompleted ? AppSpacing.sm : 0),
                child: OutlinedButton(
                  onPressed: () => _startAnotherSession(context, ref),
                  child: const Text('+ Añadir otro entrenamiento'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // planned or inProgress with a routine attached.
    final dayName = ref.watch(routineDaySessionTitleProvider(session.routineDayId)) ?? 'Entrenamiento libre';
    final hasTimeOfDay = session.date.hour != 0 || session.date.minute != 0;
    final dayExercises = session.routineDayId == null
        ? null
        : ref.watch(dayExercisesProvider(session.routineDayId!)).valueOrNull;
    final exercisesById = <int, Exercise>{
      for (final e in ref.watch(allExercisesProvider).valueOrNull ?? const <Exercise>[]) e.id: e,
    };
    final muscleSummary = _muscleSummary(dayExercises, exercisesById);

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
              Text('TU ENTRENAMIENTO DE HOY',
                  style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.accent, letterSpacing: 0.6)),
              if (session.status == SessionStatus.planned)
                TextButton(
                  onPressed: () => _pickRoutine(context, ref, existingSession: session),
                  child: const Text('Cambiar rutina'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            dayName,
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 30, height: 1.05),
          ),
          if (muscleSummary != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              muscleSummary,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          if (hasTimeOfDay) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(DateFormat('HH:mm').format(session.date),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
          if (dayExercises != null && dayExercises.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _Pill(text: '${dayExercises.length} ${dayExercises.length == 1 ? 'ejercicio' : 'ejercicios'}'),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: session.status == SessionStatus.inProgress
                  ? () => context.go('/workout')
                  : () => _startSession(context, ref, session),
              child: Text(session.status == SessionStatus.inProgress
                  ? 'CONTINUAR ENTRENAMIENTO →'
                  : 'EMPEZAR ENTRENAMIENTO →'),
            ),
          ),
        ],
      ),
    );
  }

  // Distinct primary muscles worked across the day's exercises, in the order
  // they first appear — capped at 3 so it stays a short, scannable line
  // ("Pecho · Hombros · Tríceps") instead of listing every muscle.
  String? _muscleSummary(List<RoutineExercise>? dayExercises, Map<int, Exercise> exercisesById) {
    if (dayExercises == null || dayExercises.isEmpty) return null;
    final muscles = <String>[];
    for (final routineExercise in dayExercises) {
      final exercise = exercisesById[routineExercise.exerciseId];
      if (exercise == null) continue;
      for (final muscle in exercise.primaryMuscles) {
        if (!muscles.contains(muscle)) muscles.add(muscle);
      }
    }
    if (muscles.isEmpty) return null;
    return muscles.take(3).join(' · ');
  }

  Future<void> _startSession(BuildContext context, WidgetRef ref, WorkoutSession session) async {
    final db = ref.read(appDatabaseProvider);
    await startPlannedSession(db, session: session);
    if (context.mounted) goToFreshWorkout(context);
  }

  Future<void> _viewSession(BuildContext context, WidgetRef ref, WorkoutSession session) async {
    final db = ref.read(appDatabaseProvider);
    final summary = await computeSessionSummary(db, sessionId: session.id);
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SessionSummaryScreen(summary: summary)));
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

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.accent),
      ),
    );
  }
}
