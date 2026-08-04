import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final theme = Theme.of(context);
    final restState = ref.watch(restTimerControllerProvider);
    if (!restState.isActive) return const SizedBox.shrink();

    final remaining = restState.remainingSeconds();
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    final label = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Material(
      color: theme.colorScheme.primaryContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Text(
                'Descanso: $label',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  restState.isPaused ? Icons.play_arrow : Icons.pause,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                onPressed: () {
                  final controller = ref.read(restTimerControllerProvider.notifier);
                  restState.isPaused ? controller.resume() : controller.pause();
                },
              ),
              TextButton(
                onPressed: () => ref.read(restTimerControllerProvider.notifier).skip(),
                child: const Text('Saltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
