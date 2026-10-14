import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/z_palette.dart';
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

    // La semilla del ermitaño: the rest is a senzu bean slowly being eaten
    // (it shrinks with the time left).
    return Material(
      color: Color.alphaBlend(ZColors.senzu.withValues(alpha: 0.10), theme.colorScheme.surface),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              color: ZColors.senzu,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SenzuBean(scale: 0.55 + 0.45 * progress),
                  const SizedBox(width: AppSpacing.sm),
                  Text('SEMILLA DEL ERMITAÑO', style: ZText.hud(size: 11, color: ZColors.senzu)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  _AdjustChip(label: '-15', onTap: () => controller.adjustSeconds(-15)),
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: ZText.hud(size: 32, color: ZColors.ink, spacing: 2),
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

class _SenzuBean extends StatelessWidget {
  const _SenzuBean({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 18,
      child: Center(
        child: Transform.rotate(
          angle: -0.45,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 24 * scale,
            height: 15 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.35),
                colors: [Color(0xFFC7F29A), ZColors.senzu, Color(0xFF3F7E24)],
              ),
              boxShadow: [BoxShadow(color: ZColors.senzu.withValues(alpha: 0.5), blurRadius: 8)],
            ),
          ),
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
