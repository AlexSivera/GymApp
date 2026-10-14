import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/z_palette.dart';
import '../../../services/z/masters.dart';
import '../../../services/z/mentor_lines.dart';
import '../../../services/z/z_sound.dart';
import '../providers/z_providers.dart';
import '../widgets/campaign_widgets.dart';
import '../widgets/z_media.dart';
import '../widgets/z_visuals.dart';

// "Combate de entrenamiento": a master whose trial you passed admits defeat,
// joins you and teaches their attack. (For Kaio-sama, already with you from
// the start, it's the Genkidama after the first wish.)
class MasterUnlockScreen extends ConsumerStatefulWidget {
  const MasterUnlockScreen({super.key, required this.master});

  final Master master;

  static Route<void> route(Master master) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, _) => FadeTransition(opacity: animation, child: MasterUnlockScreen(master: master)),
      );

  @override
  ConsumerState<MasterUnlockScreen> createState() => _MasterUnlockScreenState();
}

class _MasterUnlockScreenState extends ConsumerState<MasterUnlockScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ZSound.play('level_up');
      ZHaptics.boom();
      MediaQuery.of(context).disableAnimations ? _in.value = 1 : _in.forward();
    });
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final master = widget.master;
    final attack = attackById(master.attackId);
    final isMain = ref.watch(mainMasterProvider).id == master.id;
    final isKaio = master.id == 'kaio';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(opacity: 0.45, child: ZMomentBackground(slots: ['maestro_${master.id}_combate'])),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.1,
                colors: [master.color.withValues(alpha: 0.35), Colors.black.withValues(alpha: 0.92)],
              ),
            ),
          ),
          SpeedLines(color: master.color, focus: const Alignment(0, -0.3), opacity: 0.15),
          SafeArea(
            child: FitOrScroll(child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AnimatedBuilder(
                animation: _in,
                builder: (context, _) {
                  final t = Curves.easeOutCubic.transform(_in.value);
                  return Column(
                    children: [
                      Text(isKaio ? 'TÉCNICA SECRETA' : 'COMBATE DE ENTRENAMIENTO', style: ZText.hud(size: 12, color: master.color)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(isKaio ? master.name : '${master.name} vs. tú', style: ZText.display(size: 24)),
                      const SizedBox(height: AppSpacing.lg),
                      Transform.translate(
                        offset: Offset(0, 40 * (1 - t)),
                        child: Opacity(
                          opacity: t,
                          child: MentorPortrait(master: master, mood: MentorMood.riendo, size: 200, circle: false),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Opacity(
                        opacity: t,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: ZColors.panelRaised,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: master.color.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            masterUnlockSpeech[master.id] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Opacity(
                        opacity: t,
                        child: Column(
                          children: [
                            if (!isKaio)
                              Text('¡${master.name} se une como maestro!',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              constraints: const BoxConstraints(minHeight: 44),
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(colors: [attack.colors.first.withValues(alpha: 0.2), attack.colors.first, attack.colors.last]),
                              ),
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Nuevo ataque: ${attack.name}', maxLines: 1, style: ZText.display(size: 15, color: ZColors.night)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (!isKaio && !isMain)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => ref.read(zStateActionsProvider).setMainMaster(master.id),
                            child: Text('Hacer a ${master.name} mi maestro principal'),
                          ),
                        ),
                      if (isMain && !isKaio)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Text('${master.name} es ahora tu maestro principal', style: ZText.hud(size: 11, color: master.color)),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(zStateActionsProvider).setAttack(attack.id);
                            Navigator.of(context).pop();
                          },
                          child: Text('Equipar ${attack.name}'),
                        ),
                      ),
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Seguir')),
                    ],
                  );
                },
              ),
            )),
          ),
        ],
      ),
    );
  }
}
