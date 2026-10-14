import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/z_palette.dart';
import '../../../services/z/episodes.dart';
import '../../../services/z/media_pack.dart';
import '../../../services/z/z_sound.dart';
import '../widgets/z_media.dart';
import '../widgets/z_visuals.dart';

// A random anime scene from the pack, or the saga sky as a stand-in.
String _sceneSlot(String sagaSlot) {
  final scenes = filledSlots('escena_', ZMediaKind.image);
  return scenes.isEmpty ? sagaSlot : scenes[math.Random().nextInt(scenes.length)];
}

void _playNarrator(String fixed) {
  final voices = filledSlots('narrador_', ZMediaKind.audio);
  if (MediaPack.has(fixed, ZMediaKind.audio)) {
    ZSound.play(fixed);
  } else if (voices.isNotEmpty) {
    ZSound.play(voices[math.Random().nextInt(voices.length)]);
  }
}

// ----------------------------------------- ¡En el próximo episodio de GymZ!

class NextEpisodeScreen extends StatefulWidget {
  const NextEpisodeScreen({super.key, required this.text, required this.sagaSlot});

  final EpisodeText text;
  final String sagaSlot;

  static Route<void> route(EpisodeText text, String sagaSlot) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: NextEpisodeScreen(text: text, sagaSlot: sagaSlot),
        ),
      );

  @override
  State<NextEpisodeScreen> createState() => _NextEpisodeScreenState();
}

class _NextEpisodeScreenState extends State<NextEpisodeScreen> {
  late final String _scene = _sceneSlot(widget.sagaSlot);
  Timer? _auto;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _playNarrator('proximo_episodio');
    _auto = Timer(const Duration(seconds: 7), _close);
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    return Scaffold(
      backgroundColor: ZColors.mangaPaper,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _close,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const SpeedLines(color: ZColors.mangaInk, focus: Alignment.center, opacity: 0.35),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: -0.05,
                      child: Stack(
                        children: [
                          Text(
                            '¡En el próximo\nepisodio de GymZ!',
                            textAlign: TextAlign.center,
                            style: ZText.display(size: 30, height: 1).copyWith(
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 5
                                ..color = ZColors.mangaInk,
                            ),
                          ),
                          Text('¡En el próximo\nepisodio de GymZ!',
                              textAlign: TextAlign.center, style: ZText.display(size: 30, height: 1, color: ZColors.gi)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: ZColors.mangaInk, width: 3)),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 170, width: double.infinity, child: ZImage(_scene)),
                          const SizedBox(height: AppSpacing.md),
                          Text('«${text.headline}»', style: ZText.display(size: 20, color: ZColors.mangaInk)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(text.body, style: const TextStyle(color: ZColors.mangaInk, fontSize: 15, height: 1.4)),
                          if (text.footer != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(text.footer!, style: ZText.hud(size: 12, color: const Color(0xFF5B5F7A))),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Transform.rotate(angle: -0.03, child: Text('¡No te lo pierdas!', style: ZText.display(size: 22, color: ZColors.mangaInk))),
                    const SizedBox(height: AppSpacing.md),
                    Text('Toca para continuar', style: ZText.hud(size: 11, color: const Color(0xFF5B5F7A))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------- Anteriormente en GymZ…

class RecapScreen extends StatefulWidget {
  const RecapScreen({super.key, required this.pages, required this.sagaSlot});

  final List<RecapPage> pages;
  final String sagaSlot;

  static Route<void> route(List<RecapPage> pages, String sagaSlot) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, _) => FadeTransition(opacity: animation, child: RecapScreen(pages: pages, sagaSlot: sagaSlot)),
      );

  @override
  State<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends State<RecapScreen> with SingleTickerProviderStateMixin {
  static const _pageTime = Duration(milliseconds: 5000);
  late final AnimationController _progress = AnimationController(vsync: this, duration: _pageTime)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _go(1);
    });
  int _page = 0;
  late final List<String> _scenes = [for (var i = 0; i < widget.pages.length; i++) _sceneSlot(widget.sagaSlot)];

  @override
  void initState() {
    super.initState();
    _playNarrator('anteriormente');
    _progress.forward();
  }

  void _go(int delta) {
    final next = _page + delta;
    if (next >= widget.pages.length) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _page = next.clamp(0, widget.pages.length - 1));
    _progress.forward(from: 0);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.pages[_page];
    return Scaffold(
      backgroundColor: const Color(0xFF05060C),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _go(details.localPosition.dx < MediaQuery.of(context).size.width / 3 ? -1 : 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Opacity(key: ValueKey(_page), opacity: 0.55, child: ZImage(_scenes[_page])),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x3305060C), Color(0xEB05060C)],
                  stops: [0, 0.6],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) => Row(
                        children: [
                          for (var i = 0; i < widget.pages.length; i++)
                            Expanded(
                              child: Container(
                                height: 3,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.white24),
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: i < _page ? 1 : i == _page ? _progress.value : 0,
                                  child: Container(color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Column(
                        key: ValueKey(_page),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(page.kicker, style: ZText.hud(size: 12, color: ZColors.gold)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(page.title, style: ZText.display(size: 28, height: 1.1)),
                          const SizedBox(height: AppSpacing.lg),
                          for (final (big, text) in page.lines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  SizedBox(width: 78, child: Text(big, style: ZText.display(size: 20, color: ZColors.gold))),
                                  Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Toca para seguir', style: ZText.hud(size: 11, color: Colors.white54)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
