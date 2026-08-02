import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 22),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
