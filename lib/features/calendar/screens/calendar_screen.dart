import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../routines/widgets/routine_day_picker_sheet.dart';
import '../providers/calendar_providers.dart';
import '../widgets/day_detail_sheet.dart';
import '../widgets/quick_assign_sheet.dart';
import '../widgets/reorganize_dialog.dart';
import '../../../services/scheduling/bulk_assign.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedMonth = ref.watch(focusedMonthProvider);
    final sessionsAsync = ref.watch(sessionsInVisibleMonthProvider);
    final selectionMode = ref.watch(calendarSelectionModeProvider);
    final selectedDays = ref.watch(calendarSelectedDaysProvider);

    final sessionsByDay = <DateTime, WorkoutSession>{};
    for (final s in sessionsAsync.valueOrNull ?? const <WorkoutSession>[]) {
      final day = DateTime(s.date.year, s.date.month, s.date.day);
      sessionsByDay[day] = s;
    }

    Widget dayCellBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
      final normalized = DateTime(day.year, day.month, day.day);
      final session = sessionsByDay[normalized];
      final isToday = isSameDay(normalized, DateTime.now());
      final isSelected = selectedDays.contains(normalized);

      return _DayCell(
        day: normalized,
        status: session?.status,
        isToday: isToday,
        isSelectedForBulk: isSelected,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      body: Column(
        children: [
          Expanded(
            child: TableCalendar<WorkoutSession>(
              locale: 'es',
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime(2035, 12, 31),
              focusedDay: focusedMonth,
              selectedDayPredicate: (_) => false,
              onDaySelected: (selected, focused) {
                final normalized = DateTime(selected.year, selected.month, selected.day);
                ref.read(selectedDayProvider.notifier).state = normalized;
                ref.read(focusedMonthProvider.notifier).state = focused;

                if (selectionMode) {
                  final current = {...ref.read(calendarSelectedDaysProvider)};
                  if (!current.remove(normalized)) current.add(normalized);
                  ref.read(calendarSelectedDaysProvider.notifier).state = current;
                  return;
                }
                _openDay(context, ref, normalized, sessionsByDay[normalized]);
              },
              onDayLongPressed: (selected, focused) {
                final normalized = DateTime(selected.year, selected.month, selected.day);
                ref.read(calendarSelectionModeProvider.notifier).state = true;
                ref.read(calendarSelectedDaysProvider.notifier).state = {normalized};
              },
              onPageChanged: (focused) => ref.read(focusedMonthProvider.notifier).state = focused,
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) => dayCellBuilder(context, day, focusedDay),
                todayBuilder: (context, day, focusedDay) => dayCellBuilder(context, day, focusedDay),
                outsideBuilder: (context, day, focusedDay) => Opacity(
                  opacity: 0.35,
                  child: dayCellBuilder(context, day, focusedDay),
                ),
                selectedBuilder: (context, day, focusedDay) => dayCellBuilder(context, day, focusedDay),
              ),
            ),
          ),
          if (selectionMode)
            _SelectionActionBar(selectedDays: selectedDays)
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => showQuickAssignSheet(context),
                  icon: const Icon(Icons.bolt_outlined),
                  label: const Text('Asignación rápida'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openDay(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
    WorkoutSession? session,
  ) async {
    final today = DateTime.now();
    final isOverdue = day.isBefore(DateTime(today.year, today.month, today.day));
    if (session != null && session.status == SessionStatus.planned && isOverdue) {
      final handled = await showReorganizeDialog(context, ref, session: session);
      if (handled) return;
    }
    if (!context.mounted) return;
    showDayDetailSheet(context, date: day, existingSession: session);
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.status,
    required this.isToday,
    required this.isSelectedForBulk,
  });

  final DateTime day;
  final SessionStatus? status;
  final bool isToday;
  final bool isSelectedForBulk;

  Color? get _fillColor {
    switch (status) {
      case SessionStatus.completed:
        return AppTheme.statusCompleted;
      case SessionStatus.planned:
        return AppTheme.statusPlanned;
      case SessionStatus.skipped:
        return AppTheme.statusSkipped;
      case SessionStatus.rest:
        return AppTheme.statusRest;
      case SessionStatus.inProgress:
        return AppTheme.statusToday;
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = _fillColor;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        decoration: BoxDecoration(
          color: fill?.withValues(alpha: 0.22) ?? AppTheme.statusEmpty.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: AppTheme.statusToday, width: 2)
              : isSelectedForBulk
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('${day.day}', style: theme.textTheme.bodyMedium),
            if (isSelectedForBulk)
              Positioned(
                right: 2,
                top: 2,
                child: Icon(Icons.check_circle, size: 12, color: theme.colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectionActionBar extends ConsumerWidget {
  const _SelectionActionBar({required this.selectedDays});

  final Set<DateTime> selectedDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${selectedDays.length} días seleccionados', style: theme.textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(calendarSelectionModeProvider.notifier).state = false;
                  ref.read(calendarSelectedDaysProvider.notifier).state = {};
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: selectedDays.isEmpty ? null : () => _assignRoutine(context, ref),
                icon: const Icon(Icons.list_alt),
                label: const Text('Asignar rutina'),
              ),
              OutlinedButton.icon(
                onPressed: selectedDays.isEmpty ? null : () => _markRest(context, ref),
                icon: const Icon(Icons.nightlight_outlined),
                label: const Text('Marcar descanso'),
              ),
              OutlinedButton.icon(
                onPressed: selectedDays.isEmpty ? null : () => _deleteAssignments(context, ref),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar asignación'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _exit(WidgetRef ref) {
    ref.read(calendarSelectionModeProvider.notifier).state = false;
    ref.read(calendarSelectedDaysProvider.notifier).state = {};
  }

  Future<void> _assignRoutine(BuildContext context, WidgetRef ref) async {
    final day = await showRoutineDayPicker(context);
    if (day == null) return;
    final db = ref.read(appDatabaseProvider);
    final created = await assignRoutineDayToDates(db, routineDayId: day.id, dates: selectedDays);
    _exit(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Rutina asignada a $created días.')));
    }
  }

  Future<void> _markRest(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final created = await markDatesAsRest(db, dates: selectedDays);
    _exit(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$created días marcados como descanso.')));
    }
  }

  Future<void> _deleteAssignments(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final ids = <int>[];
    for (final day in selectedDays) {
      final session = await db.workoutSessionsDao.getSessionForDate(day);
      if (session != null) ids.add(session.id);
    }
    if (ids.isNotEmpty) await db.workoutSessionsDao.deleteSessions(ids);
    _exit(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${ids.length} asignaciones eliminadas.')));
    }
  }
}
