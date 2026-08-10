import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/notifications/notification_service.dart';

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

  void start(int seconds) => _restart(remaining: seconds, total: seconds);

  // +15/-15 buttons on the rest timer bar. Adjusts whichever clock is live
  // (the wall-clock endTime while running, or the frozen pausedRemaining)
  // without resetting totalSeconds, so the progress bar's fill fraction
  // keeps referring to the original rest length.
  void adjustSeconds(int delta) {
    if (state.isPaused) {
      final updated = state.pausedRemaining! + delta;
      if (updated <= 0) {
        skip();
        return;
      }
      state = RestTimerState(
        totalSeconds: updated > state.totalSeconds ? updated : state.totalSeconds,
        pausedRemaining: updated,
      );
      return;
    }
    if (!state.isRunning) return;
    final updated = state.remainingSeconds() + delta;
    if (updated <= 0) {
      _finish();
      return;
    }
    _restart(remaining: updated, total: updated > state.totalSeconds ? updated : state.totalSeconds);
  }

  void _restart({required int remaining, required int total}) {
    _ticker?.cancel();
    state = RestTimerState(totalSeconds: total, endTime: DateTime.now().add(Duration(seconds: remaining)));
    // Scheduled independently of this Dart timer so the alert still fires
    // even if the app is backgrounded (or this provider gets disposed after
    // the user navigates away — see the class doc on autoDispose below).
    NotificationService.scheduleRestTimerFinished(Duration(seconds: remaining));
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
    NotificationService.cancelRestTimerNotification();
    state = RestTimerState(totalSeconds: state.totalSeconds, pausedRemaining: remaining);
  }

  void resume() {
    if (!state.isPaused) return;
    final remaining = state.pausedRemaining!;
    start(remaining);
  }

  void skip() {
    _ticker?.cancel();
    NotificationService.cancelRestTimerNotification();
    state = const RestTimerState(totalSeconds: 0);
  }

  void _finish() {
    _ticker?.cancel();
    NotificationService.cancelRestTimerNotification();
    HapticFeedback.mediumImpact();
    state = const RestTimerState(totalSeconds: 0);
  }

  // Deliberately does NOT cancel a pending notification: this provider is
  // `autoDispose` and tears down as soon as the user leaves the exercise
  // screen, but the rest period (and the reason to be notified about it)
  // keeps going regardless of whether anything is watching it in-app.
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
