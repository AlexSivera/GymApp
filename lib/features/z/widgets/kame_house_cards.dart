import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/z_palette.dart';
import '../../../core/utils/weight_unit.dart';
import '../../../core/utils/weight_unit_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../../services/ranking_engine/rank_tier.dart';
import '../../../services/z/dragon_balls.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../ranking/widgets/rank_badge.dart';
import '../providers/z_providers.dart';
import '../screens/shenlong_screen.dart';
import 'scouter_number.dart';
import 'z_visuals.dart';

// Aura color of the warrior: a wish-unlocked aura when one is chosen,
// otherwise the current transformation's, otherwise plain white ki.
final warriorAuraColorProvider = Provider<Color>((ref) {
  final chosen = ref.watch(zStateValueProvider).aura;
  if (chosen != null) return chosen.color;
  final reading = ref.watch(powerReadingProvider);
  return reading == null ? ZColors.whiteKi : rankTierColors[reading.rank.tier]!;
});

// The user's initial inside a ki aura — the stand-in avatar until the
// avatar creator exists.
class WarriorAvatar extends ConsumerWidget {
  const WarriorAvatar({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userSettingsProvider).valueOrNull?.name?.trim();
    final color = ref.watch(warriorAuraColorProvider);
    final intensity = (ref.watch(powerReadingProvider)?.rank.subTier ?? 1) / 3;
    return _PulsingGlow(
      color: color,
      intensity: intensity,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ZColors.panelRaised,
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          name == null || name.isEmpty ? 'Z' : name.characters.first.toUpperCase(),
          style: ZText.display(size: size * 0.42, color: color),
        ),
      ),
    );
  }
}

// The avatar's aura at small sizes: a ring of ki that breathes.
class _PulsingGlow extends StatefulWidget {
  const _PulsingGlow({required this.color, required this.intensity, required this.child});

  final Color color;
  final double intensity;
  final Widget child;

  @override
  State<_PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<_PulsingGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
      _pulse.value = 0.5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        final strength = 0.45 + 0.35 * widget.intensity;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: strength * (0.6 + 0.4 * t)),
                blurRadius: 10 + 10 * t,
                spreadRadius: 1 + 3 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class KameHouseHeader extends ConsumerWidget {
  const KameHouseHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userSettingsProvider).valueOrNull?.name?.trim();
    final title = ref.watch(zStateValueProvider).title;
    final date = DateFormat('EEE d MMM', 'es').format(DateTime.now()).toUpperCase();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KAME HOUSE · $date', style: ZText.hud(size: 11, color: ZColors.ink.withValues(alpha: 0.8))),
              const SizedBox(height: AppSpacing.xs),
              Text(
                name == null || name.isEmpty ? '¡Hola, guerrero!' : '¡Hola, $name!',
                style: Theme.of(context).textTheme.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (title != null && title.isNotEmpty)
                Text(title, style: ZText.hud(size: 12, color: ZColors.gold)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        GestureDetector(onTap: () => context.go('/profile'), child: const WarriorAvatar()),
      ],
    );
  }
}

class PowerLevelCard extends ConsumerWidget {
  const PowerLevelCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(powerReadingProvider);
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.go('/ranking'),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xE61E2A66), Color(0xE6151B42)],
            ),
            border: Border.all(color: ZColors.line),
          ),
          child: reading == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('▸ NIVEL DE PODER', style: ZText.hud(size: 11)),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Sin lectura', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Termina un entrenamiento y el rastreador leerá tu poder.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: ZColors.muted),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('▸ NIVEL DE PODER', style: ZText.hud(size: 11)),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded, color: ZColors.muted, size: 20),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: ScouterNumber(
                        value: reading.level,
                        style: ZText.display(size: 44, color: ZColors.gold).copyWith(
                          shadows: [Shadow(color: ZColors.gold.withValues(alpha: 0.55), blurRadius: 22)],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AuraPill(tier: reading.rank.tier, label: reading.rank.label),
                        if (reading.nextTier != null)
                          Text(
                            'a ${reading.gradesToNextTier} ${reading.gradesToNextTier == 1 ? 'grado' : 'grados'} de ${reading.nextTier!.shortLabel}',
                            style: theme.textTheme.bodySmall?.copyWith(color: ZColors.muted),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// "● Super Saiyan II" in the transformation's aura color.
class AuraPill extends StatelessWidget {
  const AuraPill({super.key, required this.tier, required this.label});

  final RankTier tier;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = rankTierColors[tier]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color, blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

class DragonBallsCard extends ConsumerWidget {
  const DragonBallsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(dragonBallsProvider);
    final streak = ref.watch(workoutStreakProvider).valueOrNull;

    final String status;
    if (progress.canSummon) {
      status = '¡Has reunido las siete!';
    } else if (progress.thisWeekMet) {
      status = 'Esfera de esta semana conseguida';
    } else {
      final left = progress.remainingThisWeek;
      status = 'Te ${left == 1 ? 'falta 1 entreno' : 'faltan $left entrenos'} esta semana para la siguiente esfera';
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: progress.canSummon ? ZColors.ball.withValues(alpha: 0.7) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ESFERAS DEL DRAGÓN', style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.6)),
              const Spacer(),
              Text('${progress.count}/$dragonBallsToSummon',
                  style: ZText.hud(size: 13, color: ZColors.ball)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(builder: (context, constraints) {
            final size = math.min(40.0, (constraints.maxWidth - 6 * 6) / 7);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < dragonBallsToSummon; i++)
                  DragonBall(stars: i + 1, lit: i < progress.count, size: size, glow: progress.canSummon),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.md),
          Text(
            status,
            style: theme.textTheme.bodyMedium?.copyWith(color: progress.canSummon ? ZColors.ball : ZColors.muted),
          ),
          if (!progress.canSummon) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Semana: ${progress.thisWeekCompleted}/${progress.weeklyTarget} entrenos'
              '${streak != null && streak > 0 ? ' · racha de $streak ${streak == 1 ? 'día' : 'días'}' : ''}',
              style: ZText.hud(size: 11, color: ZColors.muted),
            ),
          ],
          if (progress.canSummon) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: ZColors.namek, foregroundColor: ZColors.night),
                onPressed: () => Navigator.of(context).push(ShenlongScreen.route()),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Invocar a Shenlong'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GenkidamaCard extends ConsumerWidget {
  const GenkidamaCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final genkidama = ref.watch(genkidamaProvider).valueOrNull;
    final unit = ref.watch(weightUnitProvider);
    final fill = genkidama?.fill ?? 0;

    String volume(double kg) => '${kgToDisplayUnit(kg, unit).round()}';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GENKIDAMA', style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.6, color: ZColors.kiBlue)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              GenkidamaSphere(fill: fill, size: 52),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('${genkidama?.percent ?? 0} %', style: theme.textTheme.displaySmall),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            genkidama == null || (genkidama.volumeThisWeek <= 0 && genkidama.averageVolume <= 0)
                ? 'Cada serie de la semana le da energía'
                : genkidama.isFull
                    ? '¡Lista! ${volume(genkidama.volumeThisWeek)} ${weightUnitLabel(unit)} esta semana'
                    : '${volume(genkidama.volumeThisWeek)} de ${volume(genkidama.averageVolume)} ${weightUnitLabel(unit)} (tu media)',
            style: theme.textTheme.bodySmall?.copyWith(color: ZColors.muted),
          ),
        ],
      ),
    );
  }
}

// A sphere of blue energy filled to [fill] (0..1+).
class GenkidamaSphere extends StatelessWidget {
  const GenkidamaSphere({super.key, required this.fill, this.size = 52});

  final double fill;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: fill.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _GenkidamaPainter(value)),
      ),
    );
  }
}

class _GenkidamaPainter extends CustomPainter {
  _GenkidamaPainter(this.fill);

  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final circle = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = ZColors.kiBlue.withValues(alpha: 0.25 + 0.45 * fill)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35),
    );
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0D1F3C));
    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    final top = circle.bottom - circle.height * fill;
    canvas.drawRect(
      Rect.fromLTRB(circle.left, top, circle.right, circle.bottom),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -1),
          radius: 1.4,
          colors: [Color(0xFFE6FAFF), ZColors.kiBlue, Color(0xFF1170C9)],
        ).createShader(circle),
    );
    canvas.restore();
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x99A0E6FF),
    );
  }

  @override
  bool shouldRepaint(covariant _GenkidamaPainter old) => old.fill != fill;
}

class KaioCard extends StatelessWidget {
  const KaioCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ZColors.panelRaised,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.md),
          topRight: Radius.circular(AppRadius.md),
          bottomRight: Radius.circular(AppRadius.md),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KaioAvatar(size: 42),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KAIO-SAMA', style: ZText.hud(size: 11, color: ZColors.kiBlue)),
                const SizedBox(height: 2),
                Text(message, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
