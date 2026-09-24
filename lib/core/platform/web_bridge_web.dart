import 'dart:js_interop';
import 'dart:ui' show Color;

import 'package:web/web.dart' as web;

// Web side of web_bridge.dart. Everything is wrapped in try/catch: these are
// nice-to-haves, and a browser missing one of the APIs (no Vibration API on
// iOS Safari, for instance) must never break the workout flow.

web.AudioContext? _audio;

// Browsers only let a page make sound after the user has interacted with it,
// and an AudioContext created outside a tap may start "suspended". Called
// from the tap that starts a rest period so the context is already running
// by the time the countdown ends.
void primeRestAlertAudio() {
  try {
    final ctx = _audio ??= web.AudioContext();
    if (ctx.state == 'suspended') ctx.resume();
  } catch (_) {}
}

// Three short ascending beeps plus a vibration — the web stand-in for the
// native "Descanso terminado" notification, which the PWA can't schedule.
// The tones are synthesized (no audio file), so this also works offline.
void playRestFinishedAlert() {
  try {
    web.window.navigator.vibrate(<JSNumber>[180.toJS, 90.toJS, 180.toJS, 90.toJS, 260.toJS].toJS);
  } catch (_) {}
  try {
    final ctx = _audio ??= web.AudioContext();
    if (ctx.state == 'suspended') ctx.resume();
    final start = ctx.currentTime + 0.02;
    const notes = [880.0, 880.0, 1318.5];
    for (var i = 0; i < notes.length; i++) {
      final at = start + i * 0.2;
      final oscillator = ctx.createOscillator()
        ..type = 'sine'
        ..frequency.value = notes[i];
      final gain = ctx.createGain();
      gain.gain
        ..setValueAtTime(0.0001, at)
        ..exponentialRampToValueAtTime(0.4, at + 0.015)
        ..exponentialRampToValueAtTime(0.0001, at + (i == notes.length - 1 ? 0.35 : 0.16));
      oscillator.connect(gain);
      gain.connect(ctx.destination);
      oscillator
        ..start(at)
        ..stop(at + 0.4);
    }
  } catch (_) {}
}

// Keeps the browser chrome / installed-PWA status bar the same color as the
// app's background, whichever palette is active.
void setBrowserThemeColor(Color color) {
  try {
    final hex = '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    web.document.querySelector('meta[name="theme-color"]')?.setAttribute('content', hex);
  } catch (_) {}
}
