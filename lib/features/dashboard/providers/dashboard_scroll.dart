import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';

// Inicio's scroll position, owned outside the screen so other places can send
// it back to the top: tapping the Inicio tab while already on it, and "Volver
// al inicio" after a workout (which otherwise left it wherever it was last
// scrolled, hiding the just-updated hero card).
final dashboardScrollControllerProvider = Provider<ScrollController>((ref) {
  final controller = ScrollController();
  ref.onDispose(controller.dispose);
  return controller;
});

void scrollDashboardToTop(WidgetRef ref) {
  final controller = ref.read(dashboardScrollControllerProvider);
  // The tab may still be switching in — wait a frame so the list is attached.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!controller.hasClients || controller.offset <= 0) return;
    controller.animateTo(0, duration: AppMotion.slow, curve: AppMotion.curve);
  });
}
