import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

// Shared visual pieces for editing an exercise's sets/reps/weight/rest,
// used both by the routine day editor (persists on blur via [onCommit])
// and the routine-creation flow (updates local state live via [onChanged]).
class StatNumberField extends StatelessWidget {
  const StatNumberField({
    super.key,
    required this.controller,
    required this.label,
    this.decimal = false,
    this.onChanged,
    this.onCommit,
  });

  final TextEditingController controller;
  final String label;
  final bool decimal;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCommit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            style: theme.textTheme.titleLarge,
            decoration: InputDecoration(
              hintText: '—',
              hintStyle: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
            onEditingComplete: onCommit,
            onTapOutside: onCommit == null ? null : (_) => onCommit!(),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class RestSecondsChipsRow extends StatelessWidget {
  const RestSecondsChipsRow({super.key, required this.selected, required this.onSelected});

  final int? selected;
  final ValueChanged<int> onSelected;

  static const presets = [60, 90, 120, 180];

  @override
  Widget build(BuildContext context) {
    final options = [
      ...presets,
      if (selected != null && !presets.contains(selected)) selected!,
    ]..sort();

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final seconds in options)
          _RestChip(
            label: '${seconds}s',
            selected: seconds == selected,
            onTap: () => onSelected(seconds),
          ),
      ],
    );
  }
}

class _RestChip extends StatelessWidget {
  const _RestChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
