import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/rest_timer_controller.dart';

// Persistent countdown banner driven by [restTimerControllerProvider]. Ticks
// off a fixed end time rather than a raw decrementing counter, so pausing
// and resuming stay accurate.
class RestTimerBanner extends ConsumerStatefulWidget {
  const RestTimerBanner({super.key});

  @override
  ConsumerState<RestTimerBanner> createState() => _RestTimerBannerState();
}

class _RestTimerBannerState extends ConsumerState<RestTimerBanner> {
  Timer? _uiTicker;

  @override
  void initState() {
    super.initState();
    // The controller only notifies once per second already, but this local
    // ticker keeps the displayed mm:ss in sync even between those ticks.
    _uiTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restState = ref.watch(restTimerControllerProvider);

    return AnimatedSize(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      alignment: Alignment.bottomCenter,
      child: restState.isActive ? _buildBanner(context, restState) : const SizedBox(width: double.infinity),
    );
  }

  Widget _buildBanner(BuildContext context, RestTimerState restState) {
    final theme = Theme.of(context);
    final remaining = restState.remainingSeconds();
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    final label = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final progress = restState.totalSeconds <= 0 ? 0.0 : (remaining / restState.totalSeconds).clamp(0.0, 1.0);
    final controller = ref.read(restTimerControllerProvider.notifier);

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  _AdjustChip(label: '-15', onTap: () => controller.adjustSeconds(-15)),
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(fontSize: 30),
                    ),
                  ),
                  _AdjustChip(label: '+15', onTap: () => controller.adjustSeconds(15)),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () => ref.read(restTimerControllerProvider.notifier).skip(),
                    child: const Text('Omitir'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustChip extends StatelessWidget {
  const _AdjustChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Text(label, style: theme.textTheme.titleMedium),
        ),
      ),
    );
  }
}
