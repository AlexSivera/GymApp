import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/scheduling/bulk_assign.dart';
import '../../exercise_library/screens/exercise_library_screen.dart';
import '../../routines/providers/routines_providers.dart';
import '../../routines/screens/create_routine_screen.dart';
import '../../routines/screens/routine_editor_screen.dart';
import '../../routines/widgets/routine_day_picker_sheet.dart';
import '../providers/calendar_providers.dart';
import '../widgets/day_detail_sheet.dart';
import '../widgets/quick_assign_sheet.dart';
import '../widgets/reorganize_dialog.dart';

// Calendar and Rutinas used to be separate tabs; they're merged here so
// assigning a routine to a day and managing the routines themselves happen
// in one place. The calendar starts collapsed to the current week (leaving
// room to see the routines list without scrolling) and expands to the full
// month via the chevron beneath it, which makes it easier to bulk-assign
// routines across many days at once.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final focusedMonth = ref.watch(focusedMonthProvider);
    final calendarFormat = ref.watch(calendarFormatProvider);
    final sessionsAsync = ref.watch(sessionsInVisibleMonthProvider);
    final selectionMode = ref.watch(calendarSelectionModeProvider);
    final selectedDays = ref.watch(calendarSelectedDaysProvider);
    final routinesAsync = ref.watch(routinesListProvider);

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
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          IconButton(
            tooltip: 'Ver ejercicios',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => _createRoutine(context),
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: selectionMode ? _SelectionActionBar(selectedDays: selectedDays) : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.sm, 0),
              child: Column(
                children: [
                  TableCalendar<WorkoutSession>(
                    locale: 'es',
                    firstDay: DateTime(2020, 1, 1),
                    lastDay: DateTime(2035, 12, 31),
                    focusedDay: focusedMonth,
                    calendarFormat: calendarFormat,
                    availableCalendarFormats: const {
                      CalendarFormat.week: 'Semana',
                      CalendarFormat.month: 'Mes',
                    },
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
                  IconButton(
                    tooltip: calendarFormat == CalendarFormat.week ? 'Ver mes completo' : 'Ver semana',
                    onPressed: () => ref.read(calendarFormatProvider.notifier).state =
                        calendarFormat == CalendarFormat.week ? CalendarFormat.month : CalendarFormat.week,
                    icon: AnimatedRotation(
                      duration: AppMotion.fast,
                      curve: AppMotion.curve,
                      turns: calendarFormat == CalendarFormat.week ? 0 : 0.5,
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!selectionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => showQuickAssignSheet(context),
                  icon: const Icon(Icons.bolt_outlined),
                  label: const Text('Asignación rápida'),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            child: Text('Tus rutinas', style: theme.textTheme.titleMedium),
          ),
          routinesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('$e'),
            ),
            data: (routines) {
              if (routines.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                  child: _EmptyRoutines(onCreate: () => _createRoutine(context)),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    for (final routine in routines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _RoutineCard(routine: routine),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _createRoutine(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateRoutineScreen()),
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

class _EmptyRoutines extends StatelessWidget {
  const _EmptyRoutines({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.list_alt_outlined, size: 32, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: AppSpacing.sm),
        Text('Todavía no has creado ninguna rutina', style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onCreate,
            child: const Text('Crear tu primera rutina'),
          ),
        ),
      ],
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exerciseCount = ref.watch(routineExerciseCountProvider(routine.id)).valueOrNull;

    return AppCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RoutineEditorScreen(routineId: routine.id)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Icon(Icons.fitness_center, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(routine.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${exerciseCount ?? '—'} ejercicios · actualizada ${DateFormat('d MMM', 'es').format(routine.updatedAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
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
