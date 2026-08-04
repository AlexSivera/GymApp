import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../exercise_library/screens/exercise_library_screen.dart';
import '../providers/routines_providers.dart';
import 'routine_editor_screen.dart';

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final routinesAsync = ref.watch(routinesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutinas'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createRoutine(context, ref),
        child: const Icon(Icons.add),
      ),
      body: routinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (routines) {
          if (routines.isEmpty) {
            return Center(
              child: Text(
                'Todavía no has creado ninguna rutina.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return ListTile(
                title: Text(routine.name),
                subtitle: routine.description == null || routine.description!.isEmpty
                    ? null
                    : Text(routine.description!),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RoutineEditorScreen(routineId: routine.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createRoutine(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva rutina'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ej. Push / Pull / Legs'),
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

    final id = await ref.read(routinesDaoProvider).createRoutine(
          RoutinesCompanion.insert(name: name),
        );

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RoutineEditorScreen(routineId: id)),
      );
    }
  }
}
