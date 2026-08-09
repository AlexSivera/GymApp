import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../routines/providers/routines_providers.dart';
import '../../routines/widgets/routine_day_picker_sheet.dart';
import '../../workout_session/screens/session_summary_screen.dart';
import '../../../services/insights_engine/session_summary.dart';
import '../../../services/workout_session/start_session.dart';
import '../screens/day_edit_screen.dart';

Future<void> showDayDetailSheet(
  BuildContext context, {
  required DateTime date,
  required WorkoutSession? existingSession,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => DayDetailSheet(date: date, existingSession: existingSession),
  );
}

class DayDetailSheet extends ConsumerWidget {
  const DayDetailSheet({super.key, required this.date, required this.existingSession});

  final DateTime date;
  final WorkoutSession? existingSession;

  bool get _isToday {
    final today = DateTime.now();
    return date.year == today.year && date.month == today.month && date.day == today.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = existingSession;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _capitalize(DateFormat('EEEE d MMMM', 'es').format(date)),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (session == null) ..._buildEmptyActions(context, ref) else ...[
              _buildSummary(context, ref, session),
              const SizedBox(height: AppSpacing.lg),
              _buildSessionActions(context, ref, session),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, WidgetRef ref, WorkoutSession session) {
    final theme = Theme.of(context);
    final dayName = ref.watch(routineDaySessionTitleProvider(session.routineDayId));
    final hasTimeOfDay = session.date.hour != 0 || session.date.minute != 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dayName ?? (session.status == SessionStatus.rest ? 'Descanso' : 'Entrenamiento libre'),
            style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: _statusColor(session.status), shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(_statusLabel(session.status), style: theme.textTheme.bodyMedium),
          ],
        ),
        if (hasTimeOfDay)
          Text(DateFormat('HH:mm').format(session.date),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        if (session.durationSeconds != null)
          Text('Duración: ${(session.durationSeconds! / 60).round()} min',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        if (session.notes != null && session.notes!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(session.notes!, style: theme.textTheme.bodyMedium),
        ],
        if (session.status == SessionStatus.completed) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _openSummary(context, ref, session),
              child: const Text('Ver resumen'),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildEmptyActions(BuildContext context, WidgetRef ref) {
    return [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _assignRoutine(context, ref),
          child: const Text('Asignar rutina'),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _markRest(context, ref),
          child: const Text('Marcar descanso'),
        ),
      ),
    ];
  }

  Widget _buildSessionActions(BuildContext context, WidgetRef ref, WorkoutSession session) {
    final canStart = _isToday &&
        (session.status == SessionStatus.planned) &&
        session.routineDayId != null;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (canStart)
          ElevatedButton.icon(
            onPressed: () => _start(context, ref, session),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Empezar'),
          ),
        OutlinedButton.icon(
          onPressed: () => _assignRoutine(context, ref, existingSession: session),
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Cambiar rutina'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => DayEditScreen(date: date, existingSession: session),
            ));
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar'),
        ),
        OutlinedButton.icon(
          onPressed: () => _duplicate(context, ref, session),
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Duplicar'),
        ),
        OutlinedButton.icon(
          onPressed: () => _delete(context, ref, session),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Eliminar'),
        ),
      ],
    );
  }

  Future<void> _openSummary(BuildContext context, WidgetRef ref, WorkoutSession session) async {
    final db = ref.read(appDatabaseProvider);
    final summary = await computeSessionSummary(db, sessionId: session.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SessionSummaryScreen(summary: summary)));
  }

  Future<void> _start(BuildContext context, WidgetRef ref, WorkoutSession session) async {
    final db = ref.read(appDatabaseProvider);
    await startPlannedSession(db, session: session);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    context.go('/workout');
  }

  Future<void> _assignRoutine(BuildContext context, WidgetRef ref, {WorkoutSession? existingSession}) async {
    final day = await showRoutineDayPicker(context);
    if (day == null) return;
    final db = ref.read(appDatabaseProvider);

    if (existingSession != null) {
      await db.workoutSessionsDao.updateSession(existingSession.copyWith(routineDayId: Value(day.id)));
    } else {
      await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
        date: date,
        routineDayId: Value(day.id),
        status: const Value(SessionStatus.planned),
      ));
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _markRest(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
      date: date,
      status: const Value(SessionStatus.rest),
    ));
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _duplicate(BuildContext context, WidgetRef ref, WorkoutSession session) async {
    final targetDate = await showDatePicker(
      context: context,
      initialDate: date.add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (targetDate == null || !context.mounted) return;

    final db = ref.read(appDatabaseProvider);
    final normalized = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final existing = await db.workoutSessionsDao.getSessionForDate(normalized);
    if (existing != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ese día ya tiene un entrenamiento asignado.')));
      }
      return;
    }

    await db.workoutSessionsDao.createSession(WorkoutSessionsCompanion.insert(
      date: normalized,
      routineDayId: Value(session.routineDayId),
      status: const Value(SessionStatus.planned),
    ));
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, WorkoutSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar entrenamiento'),
        content: const Text('¿Seguro que quieres eliminar el entrenamiento de este día?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(appDatabaseProvider).workoutSessionsDao.deleteSession(session.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  Color _statusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.planned:
        return AppTheme.statusPlanned;
      case SessionStatus.inProgress:
        return AppTheme.statusToday;
      case SessionStatus.completed:
        return AppTheme.statusCompleted;
      case SessionStatus.skipped:
        return AppTheme.statusSkipped;
      case SessionStatus.rest:
        return AppTheme.statusRest;
    }
  }

  String _statusLabel(SessionStatus status) {
    switch (status) {
      case SessionStatus.planned:
        return 'Planificado';
      case SessionStatus.inProgress:
        return 'En curso';
      case SessionStatus.completed:
        return 'Completado';
      case SessionStatus.skipped:
        return 'Saltado';
      case SessionStatus.rest:
        return 'Descanso';
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
