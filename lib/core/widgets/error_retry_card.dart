import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_card.dart';

// Stand-in for AsyncValue.error branches across the app — a raw exception
// message (technical, often in English) told the user nothing and gave them
// no way to recover short of restarting the app. This gives them both.
class ErrorRetryCard extends StatelessWidget {
  const ErrorRetryCard({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message ?? 'No se ha podido cargar esto.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
