import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

// Full-screen counterpart to ErrorRetryCard — used where an AsyncValue error
// would otherwise replace an entire screen's body with a raw exception
// message and no way to recover other than restarting the app.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(
              message ?? 'No se ha podido cargar esto.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
