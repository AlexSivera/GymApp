import 'package:flutter/material.dart';

// Shows the exercise's bundled reference image if it has one, otherwise a
// generic placeholder icon — custom, user-created exercises have no image.
class ExerciseThumbnail extends StatelessWidget {
  const ExerciseThumbnail({super.key, required this.imagePaths, this.size = 48});

  final List<String> imagePaths;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imagePath = imagePaths.isEmpty ? null : imagePaths.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: imagePath == null
            ? Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(Icons.fitness_center, color: theme.colorScheme.onSurfaceVariant, size: size * 0.5),
              )
            : Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.fitness_center, color: theme.colorScheme.onSurfaceVariant, size: size * 0.5),
                ),
              ),
      ),
    );
  }
}
