import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/dashboard_providers.dart';

// Date always renders — it's the one fact guaranteed to exist. The greeting
// only appears once a name is on record (onboarding makes it mandatory, but
// existing installs from before that may still have none), so this never
// shows a placeholder name.
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(userSettingsProvider).valueOrNull?.name?.trim();
    final dateLabel = _capitalize(DateFormat('EEEE, d MMMM', 'es').format(DateTime.now()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.6),
        ),
        if (name != null && name.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text('Hola, $name', style: theme.textTheme.headlineMedium)),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.waving_hand_rounded, color: AppTheme.accent, size: 22),
            ],
          ),
        ],
      ],
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
