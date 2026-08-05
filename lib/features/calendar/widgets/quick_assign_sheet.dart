import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/database/database_provider.dart';
import '../../routines/providers/routines_providers.dart';
import '../../../services/scheduling/bulk_assign.dart';

Future<void> showQuickAssignSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const QuickAssignSheet(),
  );
}

enum _Duration { oneWeek, twoWeeks, oneMonth, custom }

const _weekdayLabels = {
  DateTime.monday: 'L',
  DateTime.tuesday: 'M',
  DateTime.wednesday: 'X',
  DateTime.thursday: 'J',
  DateTime.friday: 'V',
  DateTime.saturday: 'S',
  DateTime.sunday: 'D',
};

class QuickAssignSheet extends ConsumerStatefulWidget {
  const QuickAssignSheet({super.key});

  @override
  ConsumerState<QuickAssignSheet> createState() => _QuickAssignSheetState();
}

class _QuickAssignSheetState extends ConsumerState<QuickAssignSheet> {
  int? _routineId;
  _Duration _duration = _Duration.oneWeek;
  DateTime? _customEnd;
  final Set<int> _restWeekdays = {};
  bool _saving = false;

  DateTime get _startDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _endDate {
    switch (_duration) {
      case _Duration.oneWeek:
        return _startDate.add(const Duration(days: 6));
      case _Duration.twoWeeks:
        return _startDate.add(const Duration(days: 13));
      case _Duration.oneMonth:
        return _startDate.add(const Duration(days: 29));
      case _Duration.custom:
        return _customEnd ?? _startDate.add(const Duration(days: 6));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routinesAsync = ref.watch(routinesListProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.sm,
          bottom: AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asignación rápida', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            Text('Rutina', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            routinesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (routines) {
                if (routines.isEmpty) {
                  return Text(
                    'Crea una rutina primero.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  );
                }
                _routineId ??= routines.first.id;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final r in routines)
                      ChoiceChip(
                        label: Text(r.name),
                        selected: _routineId == r.id,
                        onSelected: (_) => setState(() => _routineId = r.id),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Duración', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: const Text('1 semana'),
                  selected: _duration == _Duration.oneWeek,
                  onSelected: (_) => setState(() => _duration = _Duration.oneWeek),
                ),
                ChoiceChip(
                  label: const Text('2 semanas'),
                  selected: _duration == _Duration.twoWeeks,
                  onSelected: (_) => setState(() => _duration = _Duration.twoWeeks),
                ),
                ChoiceChip(
                  label: const Text('1 mes'),
                  selected: _duration == _Duration.oneMonth,
                  onSelected: (_) => setState(() => _duration = _Duration.oneMonth),
                ),
                ChoiceChip(
                  label: const Text('Personalizado'),
                  selected: _duration == _Duration.custom,
                  onSelected: (_) async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate.add(const Duration(days: 7)),
                      firstDate: _startDate,
                      lastDate: _startDate.add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _duration = _Duration.custom;
                        _customEnd = DateTime(picked.year, picked.month, picked.day);
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Días de descanso', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final entry in _weekdayLabels.entries)
                  FilterChip(
                    label: Text(entry.value),
                    selected: _restWeekdays.contains(entry.key),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _restWeekdays.add(entry.key);
                      } else {
                        _restWeekdays.remove(entry.key);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _routineId == null || _saving ? null : _confirm,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Generar planificación'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final db = ref.read(appDatabaseProvider);
    final created = await bulkAssignRoutine(
      db,
      routineId: _routineId!,
      startDate: _startDate,
      endDate: _endDate,
      restWeekdays: _restWeekdays,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Se han programado $created días.')));
  }
}
