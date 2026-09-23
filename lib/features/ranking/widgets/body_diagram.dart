import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

// The user's own licensed anatomy illustration (front + back view), with one
// white-on-transparent mask per muscle tinted by that muscle's rank color.
// Every mask has exactly the same size and position as its view's base
// image, so they simply stack on top of it. Muscles without a rank keep the
// illustration's own dark fill. Which mask is which muscle is documented in
// assets/body/body_muscle_map.json (the masks were cut in GIMP from the
// illustration's own lines — see design/body/ locally).
class BodyDiagram extends StatelessWidget {
  const BodyDiagram({super.key, required this.colorsByMuscle});

  final Map<String, Color> colorsByMuscle;

  // Background of the illustration, so the panel around it blends in.
  static const backgroundColor = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ColoredBox(
        color: backgroundColor,
        child: Row(
          children: [
            Expanded(child: _BodyView(base: 'front', masks: _frontMasks, colorsByMuscle: colorsByMuscle)),
            Expanded(child: _BodyView(base: 'back', masks: _backMasks, colorsByMuscle: colorsByMuscle)),
          ],
        ),
      ),
    );
  }
}

class _MuscleMask {
  const _MuscleMask(this.file, this.muscles);

  final String file;

  // App muscle names that light this mask up — first one with a rank wins.
  // Forearms accept both spellings: the exercise library says 'Antebrazos'
  // while muscle_groups.dart says 'Antebrazo'.
  final List<String> muscles;
}

const _frontMasks = [
  _MuscleMask('cuello', ['Cuello']),
  _MuscleMask('trapecio', ['Trapecio']),
  _MuscleMask('pecho', ['Pecho']),
  _MuscleMask('hombros', ['Hombros']),
  _MuscleMask('biceps', ['Bíceps']),
  _MuscleMask('antebrazo', ['Antebrazos', 'Antebrazo']),
  _MuscleMask('abdomen', ['Abdomen']),
  _MuscleMask('aductores', ['Aductores']),
  _MuscleMask('cuadriceps', ['Cuádriceps']),
  _MuscleMask('gemelos', ['Gemelos']),
];

const _backMasks = [
  _MuscleMask('trapecio', ['Trapecio']),
  _MuscleMask('hombros', ['Hombros']),
  _MuscleMask('espalda', ['Espalda']),
  _MuscleMask('dorsales', ['Espalda']),
  _MuscleMask('triceps', ['Tríceps']),
  _MuscleMask('antebrazo', ['Antebrazos', 'Antebrazo']),
  _MuscleMask('lumbares', ['Lumbares']),
  _MuscleMask('gluteos', ['Glúteos']),
  _MuscleMask('isquiotibiales', ['Isquiotibiales']),
  _MuscleMask('cuadriceps', ['Cuádriceps']),
  _MuscleMask('gemelos', ['Gemelos']),
];

// Source images are 610x1157; the bottom 5 rows are a lighter band left over
// from the original screenshot, so they're clipped off when displayed.
const _imageWidth = 610.0;
const _imageHeight = 1157.0;
const _cleanHeight = 1152.0;

class _BodyView extends StatelessWidget {
  const _BodyView({required this.base, required this.masks, required this.colorsByMuscle});

  final String base;
  final List<_MuscleMask> masks;
  final Map<String, Color> colorsByMuscle;

  Color? _colorFor(_MuscleMask mask) {
    for (final muscle in mask.muscles) {
      final color = colorsByMuscle[muscle];
      if (color != null) return color;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: _cleanHeight / _imageHeight,
        child: AspectRatio(
          aspectRatio: _imageWidth / _imageHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Decode at on-screen size rather than the full 610px — up to
              // 23 stacked full-size images would otherwise cost a lot of memory.
              final cacheWidth = (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .ceil()
                  .clamp(1, _imageWidth.toInt());
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/body/${base}_base.png',
                      cacheWidth: cacheWidth, fit: BoxFit.fill, gaplessPlayback: true),
                  for (final mask in masks)
                    if (_colorFor(mask) case final color?)
                      Image.asset(
                        'assets/body/masks/$base/${mask.file}.png',
                        cacheWidth: cacheWidth,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                        // srcIn keeps the mask's soft alpha edges and swaps
                        // its white for the rank color.
                        color: color.withValues(alpha: 0.9),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
