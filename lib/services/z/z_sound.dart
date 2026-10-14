import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'media_pack.dart';

// Sound effects from the media pack. Silent when the pack has no file for a
// sound or the user turned sound off (Ajustes) — there are no bundled
// fallback sounds on purpose.
class ZSound {
  ZSound._();

  // Mirrors ZState.soundEnabled; kept in sync by the app shell so plain
  // callbacks (a set ticked off, a timer ending) can play without a ref.
  static bool enabled = true;

  static final _players = <AudioPlayer>[];

  static Future<void> play(String slot, {double volume = 1}) async {
    if (!enabled) return;
    final file = MediaPack.file(slot, ZMediaKind.audio);
    final url = MediaPack.webUrl(slot, ZMediaKind.audio);
    if (file == null && url == null) return;
    try {
      // A small pool so overlapping effects (punch + rest end) don't cut
      // each other off.
      final player = _players.firstWhere(
        (p) => p.state != PlayerState.playing,
        orElse: () {
          final created = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
          if (_players.length < 4) _players.add(created);
          return created;
        },
      );
      await player.setVolume(volume);
      await player.play(file != null ? DeviceFileSource(file.path) : UrlSource(url!));
    } catch (_) {
      // A broken file in the pack must never break the workout flow.
    }
  }

  static Future<void> stopAll() async {
    for (final player in _players) {
      try {
        await player.stop();
      } catch (_) {}
    }
  }
}

// Haptic shorthand for the GymZ moments.
class ZHaptics {
  ZHaptics._();

  static void tap() => HapticFeedback.selectionClick();
  static void hit() => HapticFeedback.mediumImpact();
  static void boom() => HapticFeedback.heavyImpact();
}
