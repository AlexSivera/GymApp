import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/z_palette.dart';
import '../../../services/z/campaign.dart';
import '../../../services/z/masters.dart';
import '../../../services/z/media_pack.dart';
import '../../../services/z/z_sound.dart';
import '../../../services/z/z_state.dart';
import '../widgets/campaign_widgets.dart';
import '../widgets/z_visuals.dart';

// The weekly combat: your attack crosses the screen, the villain takes the
// hit (HP draining with the numbers), then K.O. with the rewards and who comes
// next — or, for a Sunday-night combat that fell short, "¡Resiste!".
class BossFightScreen extends StatefulWidget {
  const BossFightScreen({super.key, required this.event, required this.attack, this.sundayResult = false});

  final CampaignEvent event;
  final ZAttack attack;
  // Resolved on Sunday night while the app was closed (shown on next open).
  final bool sundayResult;

  static Route<void> route(CampaignEvent event, ZAttack attack, {bool sundayResult = false}) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: BossFightScreen(event: event, attack: attack, sundayResult: sundayResult),
        ),
      );

  @override
  State<BossFightScreen> createState() => _BossFightScreenState();
}

class _BossFightScreenState extends State<BossFightScreen> with SingleTickerProviderStateMixin {
  // 0–0.25 the attack · 0.25–0.65 the hit · 0.65–1 the result.
  late final AnimationController _fight = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));
  bool _hitPlayed = false;

  @override
  void initState() {
    super.initState();
    _fight.addListener(() {
      if (!_hitPlayed && _fight.value >= 0.27) {
        _hitPlayed = true;
        ZHaptics.boom();
        ZSound.play(widget.event.defeated ? 'ko' : 'punch');
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _fight.value = 1;
      } else {
        final slot = 'ataque_${widget.attack.id}';
        ZSound.play(MediaPack.has(slot, ZMediaKind.audio) ? slot : 'kamehameha');
        _fight.forward();
      }
    });
  }

  @override
  void dispose() {
    _fight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = widget.event;
    final fight = event.fight;
    final next = event.nextFight;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _fight,
        builder: (context, _) {
          final t = _fight.value;
          final beam = (t / 0.25).clamp(0.0, 1.0);
          final hit = ((t - 0.25) / 0.4).clamp(0.0, 1.0);
          final result = ((t - 0.65) / 0.35).clamp(0.0, 1.0);
          final hp = event.hpBefore + (event.hpAfter - event.hpBefore) * Curves.easeOutCubic.transform(hit);
          final shake = hit > 0 && hit < 0.6 ? math.sin(hit * 60) * 10 * (1 - hit / 0.6) : 0.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.1,
                    colors: [
                      Color.lerp(const Color(0xFF3A0E14), widget.attack.colors.first, 0.25 * (1 - result))!,
                      const Color(0xFF0A0408),
                    ],
                  ),
                ),
              ),
              if (event.defeated) SpeedLines(color: ZColors.kaioken, focus: const Alignment(0, -0.35), opacity: 0.18 * result),
              SafeArea(
                child: FitOrScroll(child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Text(
                        widget.sundayResult ? 'RESULTADO DEL COMBATE DEL DOMINGO' : 'COMBATE SEMANAL · ${fight.saga.label.toUpperCase()}',
                        style: ZText.hud(size: 11, color: const Color(0xFFFF8A8A)),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(fight.displayName, textAlign: TextAlign.center, style: ZText.display(size: 22)),
                      const SizedBox(height: AppSpacing.lg),
                      Transform.translate(
                        offset: Offset(shake, 0),
                        child: Opacity(
                          opacity: event.defeated ? 1 - 0.55 * result : 1,
                          child: VillainPortrait(fight: fight, width: 190, height: 230),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      HpBar(fraction: hp, height: 14),
                      const SizedBox(height: 4),
                      Text('VIDA ${formatHp(hp, fight.maxHp)} / ${formatHp(1, fight.maxHp)}', style: ZText.hud(size: 12, color: const Color(0xFFFFB3B3))),
                      if (event.healed > 0)
                        Text('Se había curado un ${(event.healed * 100).round()} %', style: ZText.hud(size: 10, color: ZColors.muted)),
                      const SizedBox(height: AppSpacing.md),
                      Opacity(
                        opacity: result,
                        child: Transform.scale(
                          scale: 0.7 + 0.3 * Curves.elasticOut.transform(result),
                          child: Text(
                            event.defeated ? 'K.O.' : '¡RESISTE!',
                            style: ZText.display(size: event.defeated ? 64 : 40, color: Colors.white).copyWith(
                              shadows: const [Shadow(color: ZColors.kaioken, blurRadius: 24)],
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: result,
                        child: Text(
                          event.defeated
                              ? '${widget.attack.name}: ${(event.damage * 100).round()} % de daño'
                              : '${(event.damage * 100).round()} % de daño (${event.done}/${event.target}). '
                                  'Se curará un ${fight.healPercent} % antes del próximo combate.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                      ),
                      const Spacer(),
                      if (event.defeated)
                        Opacity(
                          opacity: result,
                          child: Column(
                            children: [
                              for (final reward in _rewardChips(fight.reward))
                                Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: reward),
                              if (next != null) _NextRival(event: event, next: next),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: result >= 1 ? () => Navigator.of(context).pop() : null,
                          child: Text(event.defeated && next != null && next.saga != fight.saga ? 'Rumbo a la ${next.saga.label}' : 'Seguir'),
                        ),
                      ),
                    ],
                  ),
                )),
              ),
              // The attack crossing the screen.
              if (beam > 0 && beam < 1)
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: beam,
                      heightFactor: 0.2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              widget.attack.colors.first.withValues(alpha: 0),
                              widget.attack.colors.first,
                              widget.attack.colors.last,
                              widget.attack.colors.first,
                              widget.attack.colors.first.withValues(alpha: 0),
                            ],
                            stops: const [0, 0.3, 0.5, 0.7, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (hit > 0 && hit < 0.25)
                IgnorePointer(child: ColoredBox(color: Colors.white.withValues(alpha: 0.8 * (1 - hit / 0.25)))),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _rewardChips(CampaignReward reward) {
    final chips = <Widget>[];
    if (reward.attackId != null) {
      final attack = attackById(reward.attackId);
      chips.add(_RewardChip(label: 'Nuevo ataque', value: attack.name, colors: attack.colors));
    }
    if (reward.title != null) {
      chips.add(_RewardChip(label: 'Nuevo título', value: '«${reward.title}»', colors: const [ZColors.gold, Color(0xFFFFF2B8)]));
    }
    if (reward.auraId != null) {
      final aura = zAllAuras.firstWhere((a) => a.id == reward.auraId);
      chips.add(_RewardChip(label: 'Nueva aura', value: aura.label, colors: [aura.color, Colors.white]));
    }
    return chips;
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.label, required this.value, required this.colors});

  final String label;
  final String value;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.first.withValues(alpha: 0.14),
        border: Border.all(color: colors.first.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(colors: [colors.first.withValues(alpha: 0.3), colors.first, colors.last]),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: ZText.hud(size: 10, color: colors.first)),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextRival extends StatelessWidget {
  const _NextRival({required this.event, required this.next});

  final CampaignEvent event;
  final CampaignFight next;

  @override
  Widget build(BuildContext context) {
    final title = event.transforms
        ? '¡${event.fight.villain} se transforma!'
        : event.endsSaga
            ? '¡Rumbo a la ${next.saga.label}!'
            : 'Nuevo rival';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          VillainPortrait(fight: next, width: 56, height: 64),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: ZText.hud(size: 10, color: ZColors.gold)),
                Text(next.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                const Text('Te espera la semana que viene', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
