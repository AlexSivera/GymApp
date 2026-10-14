import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/z_palette.dart';
import '../../../services/z/power_level.dart';
import '../../../services/z/z_sound.dart';
import '../providers/z_providers.dart';

// Drop anywhere the power level is on screen: the first time it's above
// 9.000, the scouter can't take it. Happens once, ever.
class Over9000Watcher extends ConsumerStatefulWidget {
  const Over9000Watcher({super.key});

  @override
  ConsumerState<Over9000Watcher> createState() => _Over9000WatcherState();
}

class _Over9000WatcherState extends ConsumerState<Over9000Watcher> {
  // In-memory guard so two screens don't both fire before the flag lands.
  static bool _shownThisRun = false;

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(powerReadingProvider);
    final state = ref.watch(zStateProvider).valueOrNull;
    if (!_shownThisRun &&
        state != null &&
        !state.over9000Seen &&
        reading != null &&
        reading.level > over9000Threshold) {
      _shownThisRun = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(zStateActionsProvider).markOver9000Seen();
        // Let the scouter count up first.
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        if (!mounted) return;
        await showOver9000(this.context, reading.level);
      });
    }
    return const SizedBox.shrink();
  }
}

Future<void> showOver9000(BuildContext context, int level) {
  ZSound.play('scouter_explode');
  ZHaptics.boom();
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, _, _) => _Over9000(level: level),
  );
}

class _Over9000 extends StatefulWidget {
  const _Over9000({required this.level});

  final int level;

  @override
  State<_Over9000> createState() => _Over9000State();
}

class _Over9000State extends State<_Over9000> with SingleTickerProviderStateMixin {
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: _shake,
            builder: (context, child) {
              final damp = 1 - _shake.value;
              return Transform.translate(
                offset: Offset(math.sin(_shake.value * 40) * 10 * damp, math.cos(_shake.value * 33) * 6 * damp),
                child: child,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: const Color(0xFF071A12),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(48),
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    border: Border.all(color: ZColors.kaioken, width: 2),
                    boxShadow: [BoxShadow(color: ZColors.kaioken.withValues(alpha: 0.5), blurRadius: 30)],
                  ),
                  child: CustomPaint(
                    foregroundPainter: _CracksPainter(),
                    child: Column(
                      children: [
                        Text('ERROR · LECTURA FUERA DE RANGO', style: ZText.hud(size: 11, color: ZColors.kaioken)),
                        const SizedBox(height: AppSpacing.md),
                        Text('¡MÁS DE\n9.000!',
                            textAlign: TextAlign.center,
                            style: ZText.display(size: 44, color: Colors.white).copyWith(
                              shadows: const [Shadow(color: ZColors.kaioken, blurRadius: 20)],
                            )),
                        const SizedBox(height: AppSpacing.md),
                        Text('PWR ${formatPowerLevel(widget.level)}', style: ZText.hud(size: 18)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Tu nivel de poder ha roto el rastreador. Ya eres Super Saiyan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('¡Es imposible!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CracksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final origin = Offset(size.width * 0.78, size.height * 0.2);
    final rnd = math.Random(9);
    for (var i = 0; i < 7; i++) {
      final angle = i / 7 * 2 * math.pi + rnd.nextDouble() * 0.4;
      var point = origin;
      final path = Path()..moveTo(point.dx, point.dy);
      for (var step = 0; step < 4; step++) {
        final length = 14 + rnd.nextDouble() * 24;
        final a = angle + (rnd.nextDouble() - 0.5) * 0.7;
        point = point + Offset(math.cos(a), math.sin(a)) * length;
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
