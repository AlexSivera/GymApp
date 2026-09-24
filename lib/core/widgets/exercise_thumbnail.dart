import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

// Still first-frame JPEG generated for each animated GIF by
// tool/generate_thumbnails.dart. Shown underneath the GIF: it's part of the
// offline cache, so it appears instantly (and offline, before that GIF has
// ever been downloaded) while the animation loads on top of it.
String _stillFor(String path) {
  if (!path.toLowerCase().endsWith('.gif')) return path;
  final slash = path.lastIndexOf('/');
  final name = path.substring(slash + 1, path.length - 4);
  return '${path.substring(0, slash)}/thumbs/$name.jpg';
}

// Shows the exercise's bundled reference image if it has one, otherwise a
// generic placeholder icon — custom, user-created exercises have no image.
// Fills whatever space its parent gives it (wrap in a SizedBox/AspectRatio
// to control the size).
class ExerciseImage extends StatelessWidget {
  const ExerciseImage({super.key, required this.imagePaths, this.iconSize = 24, this.animated = true});

  final List<String> imagePaths;
  final double iconSize;

  // false shows only the still thumbnail (no GIF download or decoding).
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imagePath = imagePaths.isEmpty ? null : imagePaths.first;

    Widget placeholder() => Container(
          color: theme.colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(Icons.fitness_center, color: theme.colorScheme.onSurfaceVariant, size: iconSize),
        );

    if (imagePath == null) return placeholder();

    // Fades in once decoded instead of popping into an empty slot while
    // scrolling; instant when the image was already in memory.
    Widget fadeIn(BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
      if (wasSynchronouslyLoaded) return child;
      return AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: AppMotion.normal,
        curve: AppMotion.curve,
        child: child,
      );
    }

    final still = _stillFor(imagePath);
    final hasStill = still != imagePath;
    Widget image;
    if (!hasStill) {
      // Not a GIF (e.g. the few JPEG-only exercises).
      image = Image.asset(imagePath, fit: BoxFit.cover, frameBuilder: fadeIn,
          errorBuilder: (_, _, _) => placeholder());
    } else {
      final stillImage = Image.asset(still, fit: BoxFit.cover, frameBuilder: fadeIn,
          // A GIF added without re-running the thumbnail tool has no still.
          errorBuilder: (_, _, _) => const SizedBox.expand());
      image = !animated
          ? stillImage
          : Stack(
              fit: StackFit.expand,
              children: [
                stillImage,
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  frameBuilder: fadeIn,
                  // Offline and never downloaded yet: the still stays.
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ],
            );
    }

    // The illustrations are drawn on pure white, which glared on the dark
    // palette; dimmed slightly there so they sit in the UI instead of
    // shining out of it.
    if (theme.brightness == Brightness.dark) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.9, 0, 0, 0, 0, //
          0, 0.9, 0, 0, 0,
          0, 0, 0.9, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: image,
      );
    }

    return ColoredBox(color: theme.colorScheme.surfaceContainerHighest, child: image);
  }
}

// Small fixed-size thumbnail, e.g. for a ListTile's leading slot. Rounded
// square by default; pass [circular] for a fully round avatar-style crop.
class ExerciseThumbnail extends StatelessWidget {
  const ExerciseThumbnail({
    super.key,
    required this.imagePaths,
    this.size = 48,
    this.circular = false,
  });

  final List<String> imagePaths;
  final double size;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(circular ? size / 2 : 12),
      child: SizedBox(
        width: size,
        height: size,
        child: ExerciseImage(imagePaths: imagePaths, iconSize: size * 0.5),
      ),
    );
  }
}
