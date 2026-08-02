import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../data/database/app_database.dart';
import '../providers/calendar_providers.dart';
import 'day_detail_screen.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedDay = ref.watch(selectedDayProvider);
    final focusedMonth = ref.watch(focusedMonthProvider);
    final sessionsAsync = ref.watch(sessionsInVisibleMonthProvider);

    final sessionsByDay = <DateTime, List<WorkoutSession>>{};
    for (final s in sessionsAsync.valueOrNull ?? const <WorkoutSession>[]) {
      final day = DateTime(s.date.year, s.date.month, s.date.day);
      sessionsByDay.putIfAbsent(day, () => []).add(s);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      body: TableCalendar<WorkoutSession>(
        locale: 'es',
        firstDay: DateTime(2020, 1, 1),
        lastDay: DateTime(2035, 12, 31),
        focusedDay: focusedMonth,
        selectedDayPredicate: (day) => isSameDay(day, selectedDay),
        eventLoader: (day) =>
            sessionsByDay[DateTime(day.year, day.month, day.day)] ?? const [],
        onDaySelected: (selected, focused) {
          final normalized = DateTime(selected.year, selected.month, selected.day);
          ref.read(selectedDayProvider.notifier).state = normalized;
          ref.read(focusedMonthProvider.notifier).state = focused;
          final sessionsThatDay = sessionsByDay[normalized];
          final existing =
              (sessionsThatDay != null && sessionsThatDay.isNotEmpty) ? sessionsThatDay.first : null;
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DayDetailScreen(date: normalized, existingSession: existing),
          ));
        },
        onPageChanged: (focused) => ref.read(focusedMonthProvider.notifier).state = focused,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
          markerDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      ),
    );
  }
}
