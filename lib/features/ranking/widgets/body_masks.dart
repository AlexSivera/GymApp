import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

// The user's own licensed anatomy illustration, split into a front and a
// back view (assets/body/{front,back}_base.png, 610x1157), plus one
// white-on-transparent mask per muscle region with exactly the same size
// and position (assets/body/masks/<view>/<file>.png). The masks were cut in
// GIMP from the illustration's own lines — see assets/body/body_muscle_map.json.
enum BodyView { front, back }

const bodyImageSize = Size(610, 1157);

// The illustration is white line-art on a near-black (#121212) background
// baked into the PNGs, which looked like black boxes on the light and pastel
// themes. The base layer is recolored per theme instead: a color matrix maps
// that background to the theme's surface and the white lines to a theme ink
// color, and anything painted around the drawing uses [bodyPanelColor] so
// the seams disappear.
const _sourceBackground = 18.0; // 0x12
const _sourceLines = 255.0;

Color bodyPanelColor(BuildContext context) => AppColors.of(context).surface;

ColorFilter _baseLayerFilter(BuildContext context) {
  final colors = AppColors.of(context);
  final dark = Theme.of(context).brightness == Brightness.dark;
  final background = colors.surface;
  // Softer ink on the light palettes: full-strength dark outlines on white
  // read much heavier than white outlines on black.
  final ink = dark ? colors.textColor : Color.lerp(colors.mutedTextColor, colors.textColor, 0.35)!;

  List<double> row(double from, double to, int channel) {
    final scale = (to - from) / (_sourceLines - _sourceBackground);
    final offset = from - scale * _sourceBackground;
    return [
      for (var i = 0; i < 4; i++) i == channel ? scale : 0,
      offset,
    ];
  }

  double c(double unit) => unit * 255;
  return ColorFilter.matrix([
    ...row(c(background.r), c(ink.r), 0),
    ...row(c(background.g), c(ink.g), 1),
    ...row(c(background.b), c(ink.b), 2),
    0, 0, 0, 1, 0,
  ]);
}

// Every body image is decoded at this one width, whatever size it's shown
// at, so the diagram and all the Rangos thumbnails share one cached copy of
// each file instead of one per display size.
const _decodeWidth = 480;

// Mask file -> muscle (the names in muscle_groups.dart), per view.
// 'Abductores' has no region in the illustration.
const bodyMasks = <BodyView, Map<String, String>>{
  BodyView.front: {
    'cuello': 'Cuello',
    'trapecio': 'Trapecio',
    'pecho': 'Pecho',
    'hombros': 'Hombros',
    'biceps': 'Bíceps',
    'antebrazo': 'Antebrazos',
    'abdomen': 'Abdominales',
    'aductores': 'Aductores',
    'cuadriceps': 'Cuádriceps',
    'gemelos': 'Gemelos',
  },
  BodyView.back: {
    'trapecio': 'Trapecio',
    'hombros': 'Hombros',
    'espalda': 'Espalda',
    'dorsales': 'Dorsales',
    'triceps': 'Tríceps',
    'antebrazo': 'Antebrazos',
    'lumbares': 'Lumbar',
    'gluteos': 'Glúteos',
    'isquiotibiales': 'Femoral',
    'cuadriceps': 'Cuádriceps',
    'gemelos': 'Gemelos',
  },
};

typedef BodyFrame = ({BodyView view, Rect crop});

// Square crops (in 610x1157 image coordinates) framing each muscle, and each
// muscle group, for the Rangos list thumbnails. Derived from the masks'
// bounding boxes with some padding.
const muscleFrames = <String, BodyFrame>{
  'Pecho': (view: BodyView.front, crop: Rect.fromLTWH(190, 168, 279, 279)),
  'Hombros': (view: BodyView.front, crop: Rect.fromLTWH(113, 83, 432, 432)),
  'Abdominales': (view: BodyView.front, crop: Rect.fromLTWH(145, 288, 369, 369)),
  'Cuello': (view: BodyView.front, crop: Rect.fromLTWH(216, 118, 230, 230)),
  'Bíceps': (view: BodyView.front, crop: Rect.fromLTWH(106, 163, 447, 447)),
  'Antebrazos': (view: BodyView.front, crop: Rect.fromLTWH(33, 190, 577, 577)),
  'Tríceps': (view: BodyView.back, crop: Rect.fromLTWH(0, 67, 573, 573)),
  'Cuádriceps': (view: BodyView.front, crop: Rect.fromLTWH(150, 502, 360, 360)),
  'Aductores': (view: BodyView.front, crop: Rect.fromLTWH(198, 501, 268, 268)),
  'Gemelos': (view: BodyView.back, crop: Rect.fromLTWH(84, 702, 396, 396)),
  'Glúteos': (view: BodyView.back, crop: Rect.fromLTWH(163, 450, 245, 245)),
  'Femoral': (view: BodyView.back, crop: Rect.fromLTWH(120, 583, 325, 325)),
  // No region of its own: frames the hips it works on.
  'Abductores': (view: BodyView.back, crop: Rect.fromLTWH(163, 450, 245, 245)),
  'Espalda': (view: BodyView.back, crop: Rect.fromLTWH(122, 130, 320, 320)),
  'Dorsales': (view: BodyView.back, crop: Rect.fromLTWH(119, 210, 329, 329)),
  'Lumbar': (view: BodyView.back, crop: Rect.fromLTWH(170, 349, 230, 230)),
  'Trapecio': (view: BodyView.back, crop: Rect.fromLTWH(158, 138, 253, 253)),
};

// Groups spread over both views get a frame for each; see [bestGroupFrame].
const muscleGroupFrames = <String, List<BodyFrame>>{
  'Brazos': [
    (view: BodyView.front, crop: Rect.fromLTWH(33, 112, 577, 577)),
    (view: BodyView.back, crop: Rect.fromLTWH(0, 78, 610, 610)),
  ],
  'Piernas': [
    (view: BodyView.front, crop: Rect.fromLTWH(0, 472, 610, 610)),
    (view: BodyView.back, crop: Rect.fromLTWH(0, 429, 610, 610)),
  ],
  'Espalda': [(view: BodyView.back, crop: Rect.fromLTWH(41, 111, 487, 487))],
};

// The group frame whose view shows the most of [highlighted] muscles (e.g.
// Brazos flips to the back view when only Tríceps is ranked). Ties keep the
// first frame listed.
BodyFrame? bestGroupFrame(String group, Iterable<String> highlighted) {
  final frames = muscleGroupFrames[group];
  if (frames == null) return null;
  int shown(BodyFrame frame) =>
      highlighted.where((m) => bodyMasks[frame.view]!.containsValue(m)).length;
  return frames.reduce((best, frame) => shown(frame) > shown(best) ? frame : best);
}

// Mask file -> tint, for the masks of [view] whose muscle has a color.
Map<String, Color> maskTints(BodyView view, Map<String, Color> colorsByMuscle) => {
      for (final MapEntry(key: file, value: muscle) in bodyMasks[view]!.entries)
        file: ?colorsByMuscle[muscle],
    };

// One view of the illustration with the given masks tinted on top. Fills
// whatever box it's given — callers keep the 610:1157 aspect ratio.
class BodyLayers extends StatelessWidget {
  const BodyLayers({super.key, required this.view, required this.tints});

  final BodyView view;
  final Map<String, Color> tints;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: _baseLayerFilter(context),
          child: _layer('assets/body/${view.name}_base.png'),
        ),
        for (final MapEntry(key: file, value: color) in tints.entries)
          // srcIn keeps the mask's soft alpha edges and swaps its white for
          // the tint.
          _layer('assets/body/masks/${view.name}/$file.png', tint: color),
      ],
    );
  }

  Widget _layer(String asset, {Color? tint}) => Image.asset(
        asset,
        cacheWidth: _decodeWidth,
        fit: BoxFit.fill,
        gaplessPlayback: true,
        color: tint,
        colorBlendMode: tint == null ? null : BlendMode.srcIn,
      );
}
