import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// Fires a short confetti burst from the top of the screen once, right when
// this widget mounts (unless the user has "reduce motion" on). Wraps `child`
// instead of replacing it so callers keep their own Scaffold/layout intact —
// used on the moments the app should actually feel like a reward: finishing
// a workout, unlocking a new rank.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({super.key, required this.child, this.play = true});

  final Widget child;
  final bool play;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  late final ConfettiController _controller =
      ConfettiController(duration: const Duration(milliseconds: 800));
  bool _triggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_triggered || !widget.play) return;
    _triggered = true;
    if (!MediaQuery.of(context).disableAnimations) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _controller,
                blastDirection: 1.5708,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 24,
                maxBlastForce: 18,
                minBlastForce: 8,
                gravity: 0.35,
                shouldLoop: false,
                colors: [
                  colors.accent,
                  colors.statusCompleted,
                  colors.statusPlanned,
                  colors.statusRest,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
