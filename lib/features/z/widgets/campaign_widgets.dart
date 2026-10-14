import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/z_palette.dart';
import '../../../core/widgets/app_card.dart';
import '../../../services/insights_engine/daily_insight.dart';
import '../../../services/z/campaign.dart';
import '../../../services/z/masters.dart';
import '../../../services/z/media_pack.dart';
import '../../../services/z/mentor_lines.dart';
import '../../../services/z/z_sound.dart';
import '../providers/z_providers.dart';
import 'z_media.dart';

// ------------------------------------------------------------- Portraits

// A master's face: the pack cut-out for that mood, any other mood of theirs,
// or a ki orb with their kanji.
class MentorPortrait extends StatelessWidget {
  const MentorPortrait({super.key, required this.master, this.mood = MentorMood.contento, this.size = 48, this.circle = true});

  final Master master;
  final MentorMood mood;
  final double size;
  // false = the big version that peeks in: a cut-out (transparent
  // background) shows as is; a screen capture shows in a telepathy window.
  final bool circle;

  // The first filled slot: this mood, then any other face of theirs.
  String? _filledSlot() {
    final candidates = [
      'maestro_${master.id}_${mood.name}',
      for (final m in MentorMood.values) 'maestro_${master.id}_${m.name}',
      if (master.id == 'kaio') 'kaio',
    ];
    return candidates.where(zHasPackImage).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final orb = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: [Color.lerp(master.color, Colors.white, 0.35)!, master.color, Color.lerp(master.color, Colors.black, 0.45)!],
        ),
      ),
      alignment: Alignment.center,
      child: Text(master.kanji, style: ZText.display(size: size * 0.45)),
    );
    final slot = _filledSlot();
    if (slot == null) return SizedBox.square(dimension: size, child: orb);
    if (circle) {
      return SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: FutureBuilder<PackImageShape>(
            future: packImageShape(slot),
            builder: (context, snapshot) {
              final face = snapshot.data?.face;
              if (face == null) return ZImage(slot, fit: BoxFit.cover, alignment: const Alignment(0, -0.4), fallback: orb);
              // A full-body cut-out: zoom on the head over a dark orb.
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [master.color, Color.lerp(master.color, Colors.black, 0.7)!]),
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: -face.left * size / face.width,
                      top: -face.top * size / face.height,
                      width: size / face.width,
                      height: size / face.height,
                      child: ZImage(slot, fit: BoxFit.fill),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
    return SizedBox.square(
      dimension: size,
      child: FutureBuilder<PackImageShape>(
        future: packImageShape(slot),
        builder: (context, snapshot) => snapshot.data?.cutout == true
            ? ZImage(slot, fit: BoxFit.contain, alignment: Alignment.bottomCenter, fallback: orb)
            : _TelepathyWindow(
                color: master.color,
                child: ZImage(slot, fit: BoxFit.cover, alignment: const Alignment(0, -0.3), fallback: orb),
              ),
      ),
    );
  }
}

// A screen capture of a master, framed like a telepathic call.
class _TelepathyWindow extends StatelessWidget {
  const _TelepathyWindow({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 16, spreadRadius: 1)],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(14), child: child),
    );
  }
}

// What a pack image is: a cut-out (transparent background) or a screen
// capture. For a cut-out also where the head is, so round portraits can
// zoom on the face instead of showing a tiny full body.
class PackImageShape {
  const PackImageShape({required this.cutout, this.face});

  final bool cutout;
  // A square around the head, in fractions of the image's width and height.
  final Rect? face;
}

// Looks at a tiny decoded copy: transparent corners mean a cut-out; the
// head sits at the top of the opaque figure. Cached per file.
final _shapeCache = <String, Future<PackImageShape>>{};

Future<PackImageShape> packImageShape(String slot) {
  const notCutout = PackImageShape(cutout: false);
  final source = MediaPack.file(slot, ZMediaKind.image)?.path ?? MediaPack.webUrl(slot, ZMediaKind.image);
  if (source == null) return Future.value(notCutout);
  return _shapeCache.putIfAbsent(source, () async {
    try {
      final bytes = await MediaPack.bytes(slot, ZMediaKind.image);
      if (bytes == null) return notCutout;
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64);
      final image = (await codec.getNextFrame()).image;
      final data = await image.toByteData();
      if (data == null) return notCutout;
      final w = image.width;
      final h = image.height;
      int alphaAt(int x, int y) => data.getUint8((y * w + x) * 4 + 3);
      final cutout = [alphaAt(0, 0), alphaAt(w - 1, 0), alphaAt(0, h - 1), alphaAt(w - 1, h - 1)].any((a) => a < 200);
      if (!cutout) return notCutout;

      var top = -1;
      var bottom = -1;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          if (alphaAt(x, y) > 128) {
            if (top < 0) top = y;
            bottom = y;
            break;
          }
        }
      }
      final figure = bottom - top;
      if (top < 0 || figure < 8) return const PackImageShape(cutout: true);
      // The face sits a bit below the top of the figure (spiky hair above);
      // the crop covers the whole head. Tuned on the Sparking! Zero art.
      final side = figure * 0.38;
      final centreY = top + figure * 0.18;
      // Horizontal centre of what the crop covers.
      var sumX = 0;
      var count = 0;
      for (var y = top; y < centreY + side / 2; y++) {
        for (var x = 0; x < w; x++) {
          if (alphaAt(x, y) > 128) {
            sumX += x;
            count++;
          }
        }
      }
      return PackImageShape(
        cutout: true,
        face: Rect.fromCenter(
          center: Offset(sumX / count / w, centreY / h),
          width: side / w,
          height: side / h,
        ),
      );
    } catch (_) {
      return notCutout;
    }
  });
}

bool mentorHasCutout(Master master) =>
    MentorMood.values.any((m) => zHasPackImage('maestro_${master.id}_${m.name}')) || (master.id == 'kaio' && zHasPackImage('kaio'));

// A villain form: its cut-out, the villain's generic image, or a red card
// with the name.
class VillainPortrait extends StatelessWidget {
  const VillainPortrait({super.key, required this.fight, this.width = 96, this.height = 112});

  final CampaignFight fight;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final standIn = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5A1018), Color(0xFF1A0A10)]),
        border: Border.all(color: ZColors.kaioken.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          fight.villain.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 2,
          style: ZText.display(size: 14, color: const Color(0xFFFFB3B3)),
        ),
      ),
    );
    return SizedBox(
      width: width,
      height: height,
      child: ZImage(
        'jefe_${fight.id}',
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        fallback: ZImage('jefe_${fight.villainId}', fit: BoxFit.contain, alignment: Alignment.bottomCenter, fallback: standIn),
      ),
    );
  }
}

class HpBar extends StatelessWidget {
  const HpBar({super.key, required this.fraction, this.height = 10});

  final double fraction;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fraction.clamp(0.0, 1.0),
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [ZColors.kaioken, Color(0xFFFF8A3D)]),
            boxShadow: [BoxShadow(color: ZColors.kaioken.withValues(alpha: 0.7), blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}

String formatHp(double fraction, int maxHp) {
  final value = (fraction * maxHp).round();
  final digits = '$value';
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String _days(int n) => n == 1 ? '1 día' : '$n días';

// ---------------------------------------------------- Kame House: el jefe

class BossWeekCard extends ConsumerWidget {
  const BossWeekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final campaign = ref.watch(campaignProvider);
    final week = ref.watch(weekProgressProvider);
    final fight = campaign?.current;
    if (campaign == null) return const SizedBox.shrink();
    if (fight == null) {
      return AppCard(
        child: Text('Campaña completada. Nuevos enemigos llegarán pronto.', style: theme.textTheme.titleMedium),
      );
    }

    final String status;
    if (week.resolved) {
      status = '¡Victoria esta semana! ${fight.displayName} te espera la semana que viene.';
    } else if (week.remaining == 0) {
      status = 'Hoy es el combate contra ${fight.displayName}.';
    } else {
      status = 'Te ${week.remaining == 1 ? 'queda' : 'quedan'} ${_days(week.remaining)} para el combate contra ${fight.displayName}.';
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3A0E14), Color(0xFF1A0A10)]),
        border: Border.all(color: ZColors.kaioken.withValues(alpha: 0.45)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RIVAL DE LA SEMANA · ${fight.saga.label.toUpperCase()}',
                  style: ZText.hud(size: 10, color: const Color(0xFFFF8A8A)),
                ),
                const SizedBox(height: 4),
                Text(fight.villain.toUpperCase(), style: ZText.display(size: 24)),
                if (fight.form != null) Text(fight.form!, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFFFB3B3))),
                const SizedBox(height: AppSpacing.sm),
                HpBar(fraction: campaign.hp),
                const SizedBox(height: 3),
                Text(
                  'VIDA ${formatHp(campaign.hp, fight.maxHp)} / ${formatHp(1, fight.maxHp)}${campaign.hp < 0.999 ? ' · HERIDO' : ''}',
                  style: ZText.hud(size: 10, color: const Color(0xFFFFB3B3)),
                ),
                if (!week.resolved) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('TU ATAQUE ESTA SEMANA · ${(week.attack * 100).round()} %', style: ZText.hud(size: 10, color: ZColors.kiBlue)),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: week.attack,
                      minHeight: 5,
                      color: ZColors.kiBlue,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(status, style: theme.textTheme.bodySmall?.copyWith(color: ZColors.ink)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          VillainPortrait(fight: fight, width: 92, height: 128),
        ],
      ),
    );
  }
}

// --------------------------------------------- Cámara de gravedad: banner

class WeeklyBossBanner extends ConsumerWidget {
  const WeeklyBossBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaign = ref.watch(campaignProvider);
    final week = ref.watch(weekProgressProvider);
    final fight = campaign?.current;
    if (campaign == null || fight == null) return const SizedBox.shrink();
    // This session (still in progress, so not counted yet) completes the week.
    final combatToday = !week.resolved && week.done + 1 >= week.target;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(colors: [Color(0xFF3A0E14), Color(0xFF1A0A10)]),
        border: Border.all(color: ZColors.kaioken.withValues(alpha: combatToday ? 0.8 : 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  combatToday ? '¡HOY ES EL COMBATE!' : week.resolved ? 'SEMANA GANADA · GOLPE DE VENTAJA' : 'RIVAL DE LA SEMANA',
                  style: ZText.hud(size: 10, color: combatToday ? ZColors.gold : const Color(0xFFFF8A8A)),
                ),
                Text(fight.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 5),
                HpBar(fraction: campaign.hp, height: 8),
                const SizedBox(height: 3),
                Text(
                  week.resolved
                      ? 'Este entrenamiento le quitará un 10 % por adelantado'
                      : combatToday
                          ? 'Al terminar lanzarás tu ataque: ${(projectedDamage(week.done + 1, week.target) * 100).round()} % de daño'
                          : 'Semana ${week.done}/${week.target} · faltan ${_days(week.remaining)} para el combate',
                  style: ZText.hud(size: 10, color: ZColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          VillainPortrait(fight: fight, width: 54, height: 64),
        ],
      ),
    );
  }
}

// ------------------------------------------------- Your master peeks in

class MentorPeekCard extends ConsumerStatefulWidget {
  const MentorPeekCard({super.key, required this.insight});

  final DailyInsight insight;

  @override
  ConsumerState<MentorPeekCard> createState() => _MentorPeekCardState();
}

class _MentorPeekCardState extends ConsumerState<MentorPeekCard> with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  bool _hidden = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final today = DateTime.now();
    final shownToday = ref.read(zStateValueProvider).raw['peek_day'] == '${today.year}-${today.month}-${today.day}';
    if (MediaQuery.of(context).disableAnimations || shownToday) {
      _slide.value = 1;
    } else {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        _slide.forward();
        ZHaptics.tap();
        ref.read(zStateActionsProvider).markPeekShown(today);
      });
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final master = ref.watch(mainMasterProvider);
    final line = mentorTip(master.id, widget.insight);
    final cutout = mentorHasCutout(master) && !_hidden;

    final bubble = Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, cutout ? 96 : AppSpacing.lg, AppSpacing.md),
      decoration: BoxDecoration(
        color: ZColors.panelRaised,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.md),
          topRight: Radius.circular(AppRadius.md),
          bottomRight: Radius.circular(4),
          bottomLeft: Radius.circular(AppRadius.md),
        ),
        border: Border.all(color: master.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!cutout) ...[
            MentorPortrait(master: master, mood: line.mood, size: 42),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(master.name.toUpperCase(), style: ZText.hud(size: 11, color: master.color)),
                const SizedBox(height: 2),
                Text(line.text, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );

    if (!cutout) return bubble;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        bubble,
        Positioned(
          right: -18,
          bottom: 0,
          child: AnimatedBuilder(
            animation: _slide,
            builder: (context, child) {
              final t = Curves.easeOutBack.transform(_slide.value);
              return Transform.translate(
                offset: Offset(120 * (1 - t), 0),
                child: Transform.rotate(angle: -0.12 * t, alignment: Alignment.bottomRight, child: child),
              );
            },
            child: GestureDetector(
              onTap: () => setState(() => _hidden = true),
              child: MentorPortrait(master: master, mood: line.mood, size: 118, circle: false),
            ),
          ),
        ),
      ],
    );
  }
}
