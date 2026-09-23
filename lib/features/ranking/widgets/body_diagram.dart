import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import 'body_masks.dart';

// Front + back view of the user's anatomy illustration, each muscle tinted
// by that muscle's rank color. Muscles without a rank keep the
// illustration's own dark fill.
class BodyDiagram extends StatelessWidget {
  const BodyDiagram({super.key, required this.colorsByMuscle});

  final Map<String, Color> colorsByMuscle;

  static const backgroundColor = bodyBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final tints = {
      for (final entry in colorsByMuscle.entries) entry.key: entry.value.withValues(alpha: 0.9),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ColoredBox(
        color: backgroundColor,
        child: Row(
          children: [
            for (final view in BodyView.values)
              Expanded(child: _BodyView(view: view, tints: maskTints(view, tints))),
          ],
        ),
      ),
    );
  }
}

// The source images' bottom 5 rows are a lighter band left over from the
// original screenshot, so they're clipped off when displayed.
const _cleanHeight = 1152.0;

class _BodyView extends StatelessWidget {
  const _BodyView({required this.view, required this.tints});

  final BodyView view;
  final Map<String, Color> tints;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: _cleanHeight / bodyImageSize.height,
        child: AspectRatio(
          aspectRatio: bodyImageSize.aspectRatio,
          child: BodyLayers(view: view, tints: tints),
        ),
      ),
    );
  }
}
