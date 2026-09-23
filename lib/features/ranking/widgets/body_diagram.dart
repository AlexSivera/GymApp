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

// Mask file name -> app muscle (the names in muscle_groups.dart).
const _frontMasks = {
  'cuello': 'Cuello',
  'trapecio': 'Trapecio',
  'pecho': 'Pecho',
  'hombros': 'Hombros',
  'biceps': 'Bíceps',
  'antebrazo': 'Antebrazos',
  'abdomen': 'Abdomen',
  'aductores': 'Aductores',
  'cuadriceps': 'Cuádriceps',
  'gemelos': 'Gemelos',
};

const _backMasks = {
  'trapecio': 'Trapecio',
  'hombros': 'Hombros',
  'espalda': 'Espalda',
  'dorsales': 'Dorsales',
  'triceps': 'Tríceps',
  'antebrazo': 'Antebrazos',
  'lumbares': 'Lumbares',
  'gluteos': 'Glúteos',
  'isquiotibiales': 'Isquiotibiales',
  'cuadriceps': 'Cuádriceps',
  'gemelos': 'Gemelos',
};

// Source images are 610x1157; the bottom 5 rows are a lighter band left over
// from the original screenshot, so they're clipped off when displayed.
const _imageWidth = 610.0;
const _imageHeight = 1157.0;
const _cleanHeight = 1152.0;

class _BodyView extends StatelessWidget {
  const _BodyView({required this.base, required this.masks, required this.colorsByMuscle});

  final String base;
  final Map<String, String> masks;
  final Map<String, Color> colorsByMuscle;

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
                  for (final MapEntry(key: file, value: muscle) in masks.entries)
                    if (colorsByMuscle[muscle] case final color?)
                      Image.asset(
                        'assets/body/masks/$base/$file.png',
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
