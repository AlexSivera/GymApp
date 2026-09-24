import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

// Still first-frame JPEG generated for each animated GIF by
// tool/generate_thumbnails.dart. Lists and grids use it; only screens that
// are about one exercise play the actual animation.
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
  const ExerciseImage({super.key, required this.imagePaths, this.iconSize = 24, this.animated = false});

  final List<String> imagePaths;
  final double iconSize;

  // Play the GIF itself instead of its still thumbnail.
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

    final path = animated ? imagePath : _stillFor(imagePath);
    Widget image = Image.asset(
      path,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      // Fades in once decoded instead of popping into an empty slot while
      // scrolling; instant when the image was already in memory.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: AppMotion.normal,
          curve: AppMotion.curve,
          child: child,
        );
      },
      // A missing still (e.g. a GIF added without re-running the thumbnail
      // tool) falls back to the original file.
      errorBuilder: (context, error, stackTrace) => path == imagePath
          ? placeholder()
          : Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder()),
    );

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
