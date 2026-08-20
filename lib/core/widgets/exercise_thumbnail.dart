import 'package:flutter/material.dart';

// Shows the exercise's bundled reference image if it has one, otherwise a
// generic placeholder icon — custom, user-created exercises have no image.
// Fills whatever space its parent gives it (wrap in a SizedBox/AspectRatio
// to control the size).
class ExerciseImage extends StatelessWidget {
  const ExerciseImage({super.key, required this.imagePaths, this.iconSize = 24});

  final List<String> imagePaths;
  final double iconSize;

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

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder(),
    );
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
      borderRadius: BorderRadius.circular(circular ? size / 2 : 8),
      child: SizedBox(
        width: size,
        height: size,
        child: ExerciseImage(imagePaths: imagePaths, iconSize: size * 0.5),
      ),
    );
  }
}
