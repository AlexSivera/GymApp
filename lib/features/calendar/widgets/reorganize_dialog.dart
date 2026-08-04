import 'package:flutter/material.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../services/scheduling/reorganize.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Shown when opening a day whose session is still `planned` after its date
// has passed. Returns true if the user picked an action (so the caller can
// skip showing the normal day-detail sheet), false/null if dismissed.
Future<bool> showReorganizeDialog(
  BuildContext context,
  WidgetRef ref, {
  required WorkoutSession session,
}) async {
  final action = await showDialog<ReorganizeAction>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Qué quieres hacer?'),
      content: const Text('Este entrenamiento estaba planificado y la fecha ya pasó.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(ReorganizeAction.markMissed),
          child: const Text('Marcar como perdido'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ReorganizeAction.moveToNextDay),
          child: const Text('Mover al día siguiente'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ReorganizeAction.shiftFollowingChain),
          child: const Text('Reorganizar automáticamente'),
        ),
      ],
    ),
  );
  if (action == null) return false;

  final db = ref.read(appDatabaseProvider);
  await reorganizeMissedSession(db, session: session, action: action);
  return true;
}
