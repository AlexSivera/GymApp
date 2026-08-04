import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
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
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (routine) {
        if (routine == null) {
          return const Scaffold(body: Center(child: Text('Rutina no encontrada')));
        }
        if (!_descriptionInitialized) {
          _descriptionController.text = routine.description ?? '';
          _descriptionInitialized = true;
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
                onPressed: _deleteRoutine,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addDay(daysAsync.valueOrNull?.length ?? 0),
            child: const Icon(Icons.add),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _saveDescription(routine),
                onTapOutside: (_) => _saveDescription(routine),
              ),
              const SizedBox(height: 24),
              Text('Días', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              daysAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e'),
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
                            title: Text(day.name),
                            trailing: const Icon(Icons.chevron_right),
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
