import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/z_palette.dart';
import '../../../services/z/dragon_balls.dart';
import '../../../services/z/z_sound.dart';
import '../../../services/z/z_state.dart';
import '../providers/z_providers.dart';
import '../widgets/z_media.dart';
import '../widgets/z_visuals.dart';

// La invocación: the seven esferas light up one by one, the sky goes dark,
// Shenlong appears (pack video/image, or the stock storm) and grants one
// wish. Afterwards the esferas scatter and the count starts again.
class ShenlongScreen extends ConsumerStatefulWidget {
  const ShenlongScreen({super.key});

  static Route<void> route() => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, _) => FadeTransition(opacity: animation, child: const ShenlongScreen()),
      );

  @override
  ConsumerState<ShenlongScreen> createState() => _ShenlongScreenState();
}

class _ShenlongScreenState extends ConsumerState<ShenlongScreen> with TickerProviderStateMixin {
  // 0–0.45 esferas light up, 0.45–0.6 flash, 0.6–1 the dragon and the wishes.
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  late final AnimationController _scatter =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  int _litBalls = 0;
  String? _granted;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _intro.addListener(() {
      final lit = (_intro.value / 0.45 * dragonBallsToSummon).floor().clamp(0, dragonBallsToSummon);
      if (lit != _litBalls) {
        setState(() => _litBalls = lit);
        ZHaptics.tap();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (MediaQuery.of(context).disableAnimations) {
        _intro.value = 1;
      } else {
        _intro.forward();
      }
      ZSound.play('summon');
      Future.delayed(const Duration(milliseconds: 1450), () {
        if (mounted) ZHaptics.boom();
      });
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _scatter.dispose();
    super.dispose();
  }

  Future<void> _grant(GrantedWish wish, String message) async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(zStateActionsProvider).grantWish(wish);
    ZSound.play('wish');
    ZHaptics.boom();
    setState(() => _granted = message);
    await _scatter.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(zStateValueProvider);
    final progress = ref.watch(dragonBallsProvider);
    final now = DateTime.now();
    final freeWeek = ZState.freeWeekFor(now: now, thisWeekMet: progress.thisWeekMet);
    final nextAura = state.nextAura;
    final nextTitle = state.nextTitle;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _scatter]),
        builder: (context, _) {
          final t = _intro.value;
          final skyDark = ((t - 0.3) / 0.15).clamp(0.0, 1.0);
          final flash = t < 0.45 ? 0.0 : (1 - ((t - 0.45) / 0.15)).clamp(0.0, 1.0) * (t < 0.6 ? 1 : 0);
          final dragon = ((t - 0.5) / 0.25).clamp(0.0, 1.0);
          final wishes = ((t - 0.75) / 0.25).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: dragon,
                child: const ZMomentBackground(slots: ['shenlong'], loop: false),
              ),
              // The sky darkening over everything, lifting once he's here.
              ColoredBox(color: Colors.black.withValues(alpha: 0.85 * skyDark * (1 - 0.55 * dragon))),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, const Color(0xFF020805).withValues(alpha: 0.92)],
                    stops: const [0.35, 0.85],
                  ),
                ),
              ),
              SafeArea(
                child: FitOrScroll(child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          tooltip: 'Cerrar',
                          onPressed: _busy ? null : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ),
                      const Spacer(),
                      _BallsRing(lit: _litBalls, scatter: _scatter.value),
                      const SizedBox(height: AppSpacing.xl),
                      if (_granted != null)
                        Text(
                          _granted!,
                          textAlign: TextAlign.center,
                          style: ZText.display(size: 22, color: const Color(0xFFDFFFE9)).copyWith(
                            shadows: const [Shadow(color: ZColors.namek, blurRadius: 14)],
                          ),
                        )
                      else
                        Opacity(
                          opacity: wishes,
                          child: IgnorePointer(
                            ignoring: wishes < 1,
                            child: Column(
                              children: [
                                Text(
                                  'Has reunido las 7 esferas.\nPide un deseo.',
                                  textAlign: TextAlign.center,
                                  style: ZText.display(size: 21, color: const Color(0xFFDFFFE9)).copyWith(
                                    shadows: const [Shadow(color: ZColors.namek, blurRadius: 14)],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _WishTile(
                                  title: nextAura == null ? 'Un aura nueva' : 'Aura de ${nextAura.label}',
                                  subtitle: nextAura == null
                                      ? 'Ya tienes todas las auras'
                                      : 'Para tu ficha de guerrero y tu avatar',
                                  color: nextAura?.color ?? ZColors.muted,
                                  onTap: nextAura == null
                                      ? null
                                      : () => _grant(
                                            GrantedWish(at: now, type: WishType.aura, value: nextAura.id),
                                            '¡Deseo concedido!\nAura de ${nextAura.label}',
                                          ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _WishTile(
                                  title: 'Una semana libre',
                                  subtitle:
                                      'La semana del ${DateFormat('d MMM', 'es').format(freeWeek)} cuenta como cumplida aunque no entrenes',
                                  color: ZColors.senzu,
                                  onTap: () => _grant(
                                    GrantedWish(at: now, type: WishType.freeWeek, weekStart: freeWeek),
                                    '¡Deseo concedido!\nSemana libre',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _WishTile(
                                  title: nextTitle == null ? 'Un título' : 'El título «$nextTitle»',
                                  subtitle: nextTitle == null ? 'Ya tienes todos los títulos' : 'Aparece junto a tu nombre',
                                  color: ZColors.gold,
                                  onTap: nextTitle == null
                                      ? null
                                      : () => _grant(
                                            GrantedWish(at: now, type: WishType.title, value: nextTitle),
                                            '¡Deseo concedido!\n$nextTitle',
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      if (_granted == null)
                        Text(
                          'Después las esferas se dispersarán y empezarás a reunirlas de nuevo.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
                        ),
                    ],
                  ),
                )),
              ),
              IgnorePointer(child: ColoredBox(color: Colors.white.withValues(alpha: flash * 0.9))),
            ],
          );
        },
      ),
    );
  }
}

class _BallsRing extends StatelessWidget {
  const _BallsRing({required this.lit, required this.scatter});

  final int lit;
  // 0..1 — the esferas flying off in seven directions after the wish.
  final double scatter;

  @override
  Widget build(BuildContext context) {
    const size = 34.0;
    return SizedBox(
      height: 90,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < dragonBallsToSummon; i++)
              Builder(builder: (context) {
                // A shallow arc.
                final fraction = i / (dragonBallsToSummon - 1);
                final x = width * 0.08 + (width * 0.84 - size) * fraction;
                final y = 40 - math.sin(fraction * math.pi) * 34;
                final angle = -math.pi / 2 + (fraction - 0.5) * math.pi * 1.4;
                final fly = Curves.easeInCubic.transform(scatter) * 600;
                return Positioned(
                  left: x + math.cos(angle) * fly,
                  top: y + math.sin(angle) * fly,
                  child: Opacity(
                    opacity: 1 - scatter,
                    child: DragonBall(stars: i + 1, lit: i < lit, size: size, glow: i < lit),
                  ),
                );
              }),
          ],
        );
      }),
    );
  }
}

class _WishTile extends StatelessWidget {
  const _WishTile({required this.title, required this.subtitle, required this.color, required this.onTap});

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        color: color.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withValues(alpha: 0.55)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: Color(0xFFA7CDB7), fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.auto_awesome, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
