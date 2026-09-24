import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

// A short celebratory banner that drops in under the status bar and leaves on
// its own. Used instead of a SnackBar for moments during a workout: a
// SnackBar lives at the bottom of the screen, right on top of the rest-timer
// controls the user needs at that exact moment.
//
// Takes the app's root [OverlayState] (`Overlay.of(context, rootOverlay:
// true)`) rather than a BuildContext, so callers can grab it up front and
// still show the toast after awaiting — by then the widget that triggered it
// may already be gone.
void showTopToast(
  OverlayState overlay, {
  required IconData icon,
  required String message,
  Color? iconColor,
  Duration duration = const Duration(milliseconds: 2600),
}) {
  if (!overlay.mounted) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TopToast(
      icon: icon,
      message: message,
      iconColor: iconColor,
      duration: duration,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _TopToast extends StatefulWidget {
  const _TopToast({
    required this.icon,
    required this.message,
    required this.iconColor,
    required this.duration,
    required this.onDone,
  });

  final IconData icon;
  final String message;
  final Color? iconColor;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: AppMotion.slow, reverseDuration: AppMotion.normal);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _controller, curve: AppMotion.curve),
            child: SlideTransition(
              position: Tween(begin: const Offset(0, -0.6), end: Offset.zero).animate(curved),
              child: Center(
                child: Material(
                  color: colors.surfaceRaised,
                  elevation: 6,
                  shadowColor: Colors.black54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    side: BorderSide(color: colors.border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: _dismiss,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon, color: widget.iconColor ?? colors.accent, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(child: Text(widget.message, style: theme.textTheme.labelLarge)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
