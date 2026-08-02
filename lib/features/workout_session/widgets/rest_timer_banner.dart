import 'dart:async';

import 'package:flutter/material.dart';

// Simple in-app countdown shown after logging a set. Re-mount with a new
// key (e.g. ValueKey(incrementingNonce)) to restart it for the next set.
class RestTimerBanner extends StatefulWidget {
  const RestTimerBanner({super.key, required this.seconds, required this.onFinished});

  final int seconds;
  final VoidCallback onFinished;

  @override
  State<RestTimerBanner> createState() => _RestTimerBannerState();
}

class _RestTimerBannerState extends State<RestTimerBanner> {
  late int _remaining = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _timer?.cancel();
        widget.onFinished();
        return;
      }
      setState(() => _remaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
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
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _timer?.cancel();
                  widget.onFinished();
                },
                child: const Text('Saltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
