import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/z_palette.dart';
import '../../../services/z/z_sound.dart';

// "Mantén para lanzar el Kamehameha": hold to charge, release once full to
// fire. Letting go early just drains the charge — which is also what makes
// it impossible to end a workout by accident.
class KamehamehaButton extends StatefulWidget {
  const KamehamehaButton({super.key, required this.onFire, this.label = 'Mantén para lanzar el Kamehameha'});

  final VoidCallback onFire;
  final String label;

  @override
  State<KamehamehaButton> createState() => _KamehamehaButtonState();
}

class _KamehamehaButtonState extends State<KamehamehaButton> with SingleTickerProviderStateMixin {
  static const _chargeTime = Duration(milliseconds: 1500);

  late final AnimationController _charge = AnimationController(vsync: this, duration: _chargeTime)
    ..addListener(_onTick)
    ..addStatusListener(_onStatus);
  int _lastBuzz = 0;
  bool _fired = false;

  void _onTick() {
    // Vibration ramps up with the charge: a tick every 20%.
    final step = (_charge.value * 5).floor();
    if (step > _lastBuzz) {
      _lastBuzz = step;
      step >= 4 ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_fired) {
      _fired = true;
      HapticFeedback.heavyImpact();
      ZSound.play('kamehameha');
      widget.onFire();
    }
  }

  void _start() {
    if (_fired) return;
    _lastBuzz = 0;
    ZSound.play('ki_charge', volume: 0.8);
    _charge.forward();
  }

  void _cancel() {
    if (_fired) return;
    _charge.animateBack(0, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() {
    _charge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _start(),
        onTapUp: (_) => _cancel(),
        onTapCancel: _cancel,
        child: AnimatedBuilder(
          animation: _charge,
          builder: (context, _) {
            final v = _charge.value;
            return Container(
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF0B1B3A),
                border: Border.all(color: ZColors.kiBlue.withValues(alpha: 0.4 + 0.6 * v), width: 1.5),
                boxShadow: [
                  BoxShadow(color: ZColors.kiBlue.withValues(alpha: 0.15 + 0.5 * v), blurRadius: 10 + 24 * v),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0x223CC8FF), Color(0xCC3CC8FF), Color(0xFFE6FAFF)],
                          stops: [0, 0.85, 1],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              v >= 1 ? '¡KAMEHAMEHA!' : widget.label,
                              style: ZText.display(size: v >= 1 ? 18 : 14, color: ZColors.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('${(v * 100).round()} %', style: ZText.hud(size: 13, color: const Color(0xFFBFEFFF))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// The beam that crosses the screen right after firing — a white-blue flash
// sweeping left to right, then fading. Pushed as a transparent route.
class KamehamehaBeamRoute extends PageRouteBuilder<void> {
  KamehamehaBeamRoute()
      : super(
          opaque: false,
          barrierDismissible: false,
          transitionDuration: const Duration(milliseconds: 650),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, animation, _) => _Beam(animation: animation),
        );
}

class _Beam extends StatelessWidget {
  const _Beam({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final v = Curves.easeOutCubic.transform(animation.value);
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: Colors.white.withValues(alpha: 0.35 * v))),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: v,
                  heightFactor: 0.22 + 0.2 * v,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x003CC8FF), Color(0xFF3CC8FF), Colors.white, Color(0xFF3CC8FF), Color(0x003CC8FF)],
                        stops: [0, 0.3, 0.5, 0.7, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
