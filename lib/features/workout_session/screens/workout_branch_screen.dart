import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_retry_view.dart';
import '../providers/workout_session_providers.dart';
import 'workout_session_screen.dart';

// Root of the "Entreno" nav branch. There is no `/workout/:id` URL — this
// widget always resolves the current in-progress session itself, so the
// branch stays trivially deep-link-safe and the bottom nav never needs to
// know a session id.
class WorkoutBranchScreen extends ConsumerWidget {
  const WorkoutBranchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider);

    return activeSession.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: ErrorRetryView(
          message: 'No se ha podido cargar el entrenamiento.',
          onRetry: () => ref.invalidate(activeSessionProvider),
        ),
      ),
      data: (session) {
        if (session == null) {
          // Only reachable for a brief instant while a session is being
          // completed/deleted and the tab hasn't hidden itself yet.
          return const Scaffold(body: SizedBox.shrink());
        }
        return WorkoutSessionScreen(sessionId: session.id);
      },
    );
  }
}
