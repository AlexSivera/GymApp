import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestTimerState {
  const RestTimerState({required this.totalSeconds, this.endTime, this.pausedRemaining});

  final int totalSeconds;
  // Wall-clock end time while running — using a fixed instant (not a
  // decrementing counter) means the countdown stays correct even if the
  // widget tree rebuilds or the screen is briefly backgrounded.
  final DateTime? endTime;
  final int? pausedRemaining;

  bool get isRunning => endTime != null;
  bool get isPaused => pausedRemaining != null;
  bool get isActive => isRunning || isPaused;

  int remainingSeconds([DateTime? now]) {
    if (pausedRemaining != null) return pausedRemaining!;
    if (endTime == null) return 0;
    final diff = endTime!.difference(now ?? DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  RestTimerState _tick() =>
      RestTimerState(totalSeconds: totalSeconds, endTime: endTime, pausedRemaining: pausedRemaining);
}

class RestTimerController extends StateNotifier<RestTimerState> {
  RestTimerController() : super(const RestTimerState(totalSeconds: 0));

  Timer? _ticker;

  void start(int seconds) {
    _ticker?.cancel();
    state = RestTimerState(totalSeconds: seconds, endTime: DateTime.now().add(Duration(seconds: seconds)));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds() <= 0) {
        _finish();
      } else {
        state = state._tick();
      }
    });
  }

  void pause() {
    if (!state.isRunning) return;
    final remaining = state.remainingSeconds();
    _ticker?.cancel();
    state = RestTimerState(totalSeconds: state.totalSeconds, pausedRemaining: remaining);
  }

  void resume() {
    if (!state.isPaused) return;
    final remaining = state.pausedRemaining!;
    start(remaining);
  }

  void skip() {
    _ticker?.cancel();
    state = const RestTimerState(totalSeconds: 0);
  }

  void _finish() {
    _ticker?.cancel();
    HapticFeedback.mediumImpact();
    state = const RestTimerState(totalSeconds: 0);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final restTimerControllerProvider =
    StateNotifierProvider.autoDispose<RestTimerController, RestTimerState>(
  (ref) => RestTimerController(),
);
