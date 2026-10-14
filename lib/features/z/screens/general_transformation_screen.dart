import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/z_palette.dart';
import '../../../services/ranking_engine/rank_tier.dart';
import '../../../services/z/media_pack.dart';
import '../../../services/z/power_level.dart';
import '../../../services/z/z_sound.dart';
import '../../ranking/widgets/rank_badge.dart';
import '../providers/z_providers.dart';
import '../widgets/z_media.dart';

// The big one: when the whole-body average reaches a form you've never
// reached before, its clip from the pack plays full screen with sound
// (forma_<form>.mp4), or the form's image if there's no clip. The highest
// form reached is stored: a dip (a new, weaker exercise) never replays a
// clip, and jumping several forms at once plays every skipped one in order.
// The first reading plays every form already reached, from SSJ up.
class GeneralTransformationWatcher extends ConsumerStatefulWidget {
  const GeneralTransformationWatcher({super.key});

  @override
  ConsumerState<GeneralTransformationWatcher> createState() => _GeneralTransformationWatcherState();
}

class _GeneralTransformationWatcherState extends ConsumerState<GeneralTransformationWatcher> {
  // In-memory guard so two screens don't both fire before the value lands.
  static int? _handledTier;

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(powerReadingProvider);
    final state = ref.watch(zStateProvider).valueOrNull;
    final visible = TickerMode.valuesOf(context).enabled && (ModalRoute.of(context)?.isCurrent ?? true);
    if (!visible || state == null || reading == null) return const SizedBox.shrink();

    final tier = reading.rank.tier.index;
    // Nothing celebrated yet = you start as a plain Saiyan, so the first
    // reading plays every form you've already reached, in order.
    final best = state.generalTierSeen ?? 0;
    if (_handledTier != null && tier <= _handledTier!) return const SizedBox.shrink();
    if (tier <= best) {
      if (state.generalTierSeen == null) {
        _handledTier = tier;
        WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(zStateActionsProvider).setGeneralTierSeen(tier));
      }
      return const SizedBox.shrink();
    }

    _handledTier = tier;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(zStateActionsProvider).setGeneralTierSeen(tier);
      for (var i = best + 1; i <= tier; i++) {
        if (!mounted) return;
        await Navigator.of(this.context).push(GeneralTransformationScreen.route(RankTier.values[i], reading.level));
      }
    });
    return const SizedBox.shrink();
  }
}

class GeneralTransformationScreen extends StatefulWidget {
  const GeneralTransformationScreen({super.key, required this.tier, required this.level});

  final RankTier tier;
  final int level;

  static Route<void> route(RankTier tier, int level) => PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, _) =>
            FadeTransition(opacity: animation, child: GeneralTransformationScreen(tier: tier, level: level)),
      );

  @override
  State<GeneralTransformationScreen> createState() => _GeneralTransformationScreenState();
}

class _GeneralTransformationScreenState extends State<GeneralTransformationScreen> with SingleTickerProviderStateMixin {
  // The texts come in once the clip has had its moment.
  late final AnimationController _text =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  String get _clip => 'forma_${widget.tier.slug}';

  @override
  void initState() {
    super.initState();
    final hasClip = MediaPack.has(_clip, ZMediaKind.video);
    // The clip brings its own sound.
    if (!hasClip) ZSound.play('transform');
    ZHaptics.boom();
    Future.delayed(Duration(milliseconds: hasClip ? 2500 : 600), () {
      if (mounted) _text.forward();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = rankTierColors[widget.tier]!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ZMomentBackground(slots: [_clip, 'transform_${widget.tier.slug}', 'transform'], loop: false, withSound: true),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.transparent, Color(0xD9000000)],
                stops: [0, 0.55, 0.85],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AnimatedBuilder(
                animation: _text,
                builder: (context, _) {
                  final t = Curves.easeOutCubic.transform(_text.value);
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - t)),
                      child: Column(
                        children: [
                          const Spacer(),
                          Text('TRANSFORMACIÓN', style: ZText.hud(size: 13, color: Colors.white70)),
                          const SizedBox(height: AppSpacing.xs),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.tier.label.toUpperCase(),
                              maxLines: 1,
                              style: ZText.display(size: 34, color: Colors.white).copyWith(
                                shadows: [Shadow(color: color, blurRadius: 22), Shadow(color: color, blurRadius: 6)],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'La media de todo tu cuerpo ya es ${widget.tier.label}. Nivel de poder: ${formatPowerLevel(widget.level)}.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black),
                              onPressed: _text.value < 1 ? null : () => Navigator.of(context).pop(),
                              child: const Text('Seguir'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
