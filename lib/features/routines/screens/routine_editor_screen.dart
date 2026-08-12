import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_retry_card.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../data/database/app_database.dart';
import '../providers/routines_providers.dart';
import 'routine_day_editor_screen.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  const RoutineEditorScreen({super.key, required this.routineId});

  final int routineId;

  @override
  ConsumerState<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  late final TextEditingController _descriptionController;
  bool _descriptionInitialized = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _renameRoutine(Routine routine) async {
    final controller = TextEditingController(text: routine.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar rutina'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(routinesDaoProvider).updateRoutine(routine.copyWith(name: name));
  }

  Future<void> _saveDescription(Routine routine) async {
    await ref.read(routinesDaoProvider).updateRoutine(
          routine.copyWith(description: Value(_descriptionController.text.trim())),
        );
  }

  Future<void> _deleteRoutine() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar rutina'),
        content: const Text('Se eliminarán también todos sus días y ejercicios. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(routinesDaoProvider).deleteRoutine(widget.routineId);
    if (mounted) Navigator.of(context).pop();
  }

  // Archiving keeps the routine and its history intact (unlike eliminar) —
  // it just drops off the main "Tus rutinas" list, reachable again from
  // "Rutinas archivadas" if you want to reuse or unarchive it later.
  Future<void> _archiveRoutine() async {
    await ref.read(routinesDaoProvider).setArchived(widget.routineId, true);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rutina archivada.')));
    }
  }

  Future<void> _addDay(int currentDayCount) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo día'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ej. Push A'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(routinesDaoProvider).createDay(RoutineDaysCompanion.insert(
          routineId: widget.routineId,
          name: name,
          dayOrder: currentDayCount,
        ));
  }

  // A routine created via "Crear rutina" starts as a single day named "Día 1"
  // internally — a placeholder that routineDaySessionTitleProvider hides for
  // as long as the routine has only one day. The moment a second day exists,
  // that fallback stops applying and both days show their real names, so
  // this asks for a name for the existing day *before* it becomes visible,
  // then for the new day's name — turning a flat routine into a real
  // multi-day one (Empuje/Tirón/Pierna, Torso/Pierna...) without ever
  // leaking "Día 1" onto a screen.
  Future<void> _convertToMultiDay(RoutineDay currentDay) async {
    final currentDayName = await _promptDayName(
      title: 'Nombra el día actual',
      hint: 'Ej. Empuje',
    );
    if (currentDayName == null || currentDayName.isEmpty) return;
    if (!mounted) return;
    await ref.read(routinesDaoProvider).updateDay(currentDay.copyWith(name: currentDayName));

    final newDayName = await _promptDayName(
      title: 'Nombra el nuevo día',
      hint: 'Ej. Tirón',
    );
    if (newDayName == null || newDayName.isEmpty) return;
    await ref.read(routinesDaoProvider).createDay(RoutineDaysCompanion.insert(
          routineId: widget.routineId,
          name: newDayName,
          dayOrder: 1,
        ));
  }

  Future<String?> _promptDayName({required String title, required String hint}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<void> _reorderDays(List<RoutineDay> current, int oldIndex, int newIndex) async {
    final list = [...current];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await ref.read(routinesDaoProvider).reorderDays(list.map((d) => d.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routineAsync = ref.watch(routineProvider(widget.routineId));
    final daysAsync = ref.watch(routineDaysProvider(widget.routineId));

    return routineAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: ErrorRetryView(
          message: 'No se ha podido cargar la rutina.',
          onRetry: () => ref.invalidate(routineProvider(widget.routineId)),
        ),
      ),
      data: (routine) {
        if (routine == null) {
          return const Scaffold(body: Center(child: Text('Rutina no encontrada')));
        }
        if (!_descriptionInitialized) {
          _descriptionController.text = routine.description ?? '';
          _descriptionInitialized = true;
        }

        final days = daysAsync.valueOrNull;

        // A routine with exactly one day is the common case (every routine
        // created via "Crear Rutina" starts this way): show its exercises
        // directly under the routine instead of forcing an extra tap into a
        // "Días" list with a single, invisible-purpose entry.
        if (days != null && days.length == 1) {
          return _SingleDayRoutineView(
            routine: routine,
            day: days.first,
            descriptionController: _descriptionController,
            onRenameRoutine: () => _renameRoutine(routine),
            onSaveDescription: () => _saveDescription(routine),
            onDeleteRoutine: _deleteRoutine,
            onArchiveRoutine: _archiveRoutine,
            onAddDay: () => _convertToMultiDay(days.first),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(routine.name),
            actions: [
              IconButton(
                onPressed: () => _renameRoutine(routine),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: _archiveRoutine,
                tooltip: 'Archivar rutina',
                icon: const Icon(Icons.archive_outlined),
              ),
              IconButton(
                onPressed: _deleteRoutine,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addDay(days?.length ?? 0),
            child: const Icon(Icons.add),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                onSubmitted: (_) => _saveDescription(routine),
                onTapOutside: (_) => _saveDescription(routine),
              ),
              const SizedBox(height: 24),
              Text('Días', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              daysAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorRetryCard(
                  message: 'No se han podido cargar los días.',
                  onRetry: () => ref.invalidate(routineDaysProvider(widget.routineId)),
                ),
                data: (days) {
                  if (days.isEmpty) {
                    return Text(
                      'Añade un día de entrenamiento con el botón +.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    );
                  }
                  return ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: days.length,
                    onReorderItem: (oldIndex, newIndex) => _reorderDays(days, oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final day = days[index];
                      return Padding(
                        key: ValueKey(day.id),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.calendar_today_outlined,
                                  size: 18, color: theme.colorScheme.primary),
                            ),
                            title: Text(day.name),
                            trailing: Icon(Icons.chevron_right,
                                size: 20, color: theme.colorScheme.onSurfaceVariant),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => RoutineDayEditorScreen(
                                routineDayId: day.id,
                                dayName: day.name,
                              ),
                            )),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _RoutineMenuAction { rename, addDay, archive, delete }

// Merged view for the single-day case: the routine IS the day, so its
// exercises show up directly instead of behind a "Días" list with one entry.
// There's deliberately no "Añadir otro día" here — a routine created this way
// (the only way to create one) stays flat forever; splitting a workout into
// parts means creating separate routines (Push, Pull, Legs...), not nesting
// days inside one. Renombrar/Eliminar move into an overflow menu to keep the
// app bar focused on "Empezar".
class _SingleDayRoutineView extends ConsumerWidget {
  const _SingleDayRoutineView({
    required this.routine,
    required this.day,
    required this.descriptionController,
    required this.onRenameRoutine,
    required this.onSaveDescription,
    required this.onDeleteRoutine,
    required this.onArchiveRoutine,
    required this.onAddDay,
  });

  final Routine routine;
  final RoutineDay day;
  final TextEditingController descriptionController;
  final VoidCallback onRenameRoutine;
  final VoidCallback onSaveDescription;
  final VoidCallback onDeleteRoutine;
  final VoidCallback onArchiveRoutine;
  final VoidCallback onAddDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(dayExercisesProvider(day.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(routine.name),
        actions: [
          if ((exercisesAsync.valueOrNull ?? const []).isNotEmpty)
            TextButton.icon(
              onPressed: () => startWorkoutFromDay(context, ref, day.id),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Empezar'),
            ),
          PopupMenuButton<_RoutineMenuAction>(
            onSelected: (action) {
              switch (action) {
                case _RoutineMenuAction.rename:
                  onRenameRoutine();
                case _RoutineMenuAction.addDay:
                  onAddDay();
                case _RoutineMenuAction.archive:
                  onArchiveRoutine();
                case _RoutineMenuAction.delete:
                  onDeleteRoutine();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _RoutineMenuAction.rename, child: Text('Renombrar rutina')),
              PopupMenuItem(value: _RoutineMenuAction.addDay, child: Text('Añadir otro día')),
              PopupMenuItem(value: _RoutineMenuAction.archive, child: Text('Archivar rutina')),
              PopupMenuItem(value: _RoutineMenuAction.delete, child: Text('Eliminar rutina')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addExercisesToDay(context, ref, day.id),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
              onSubmitted: (_) => onSaveDescription(),
              onTapOutside: (_) => onSaveDescription(),
            ),
          ),
          Expanded(child: DayExercisesList(routineDayId: day.id)),
        ],
      ),
    );
  }
}
