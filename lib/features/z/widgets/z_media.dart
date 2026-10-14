import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../services/z/media_pack.dart';

// An image slot of the media pack: the user's file when the pack has one,
// otherwise the slot's stock photo, otherwise [fallback] (or nothing).
class ZImage extends StatelessWidget {
  const ZImage(this.slot, {super.key, this.fit = BoxFit.cover, this.alignment = Alignment.center, this.fallback});

  final String slot;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MediaPack.revision,
      builder: (context, _, _) {
        final provider = zImageProvider(slot);
        if (provider == null) return fallback ?? const SizedBox.shrink();
        return Image(
          image: provider,
          fit: fit,
          alignment: alignment,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => fallback ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

ImageProvider? zImageProvider(String slot) {
  final file = MediaPack.file(slot, ZMediaKind.image);
  if (file != null) return FileImage(file);
  final url = MediaPack.webUrl(slot, ZMediaKind.image);
  if (url != null) return NetworkImage(url);
  final stock = stockAssetFor(slot);
  return stock == null ? null : AssetImage(stock);
}

bool zHasPackImage(String slot) => MediaPack.has(slot, ZMediaKind.image);

// Full-bleed background for a GymZ moment: the first slot in [slots] that
// has a video in the pack plays (muted unless [withSound], looping unless
// [loop] is false); otherwise the first slot with an image (pack or stock)
// is shown.
class ZMomentBackground extends StatefulWidget {
  const ZMomentBackground({super.key, required this.slots, this.loop = true, this.withSound = false});

  final List<String> slots;
  final bool loop;
  final bool withSound;

  @override
  State<ZMomentBackground> createState() => _ZMomentBackgroundState();
}

class _ZMomentBackgroundState extends State<ZMomentBackground> {
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    for (final slot in widget.slots) {
      final file = MediaPack.file(slot, ZMediaKind.video);
      final url = MediaPack.webUrl(slot, ZMediaKind.video);
      if (file == null && url == null) continue;
      final controller = file != null ? VideoPlayerController.file(file) : VideoPlayerController.networkUrl(Uri.parse(url!));
      try {
        await controller.initialize();
        await controller.setLooping(widget.loop);
        await controller.setVolume(widget.withSound ? 1 : 0);
        await controller.play();
      } catch (_) {
        await controller.dispose();
        continue;
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _video = controller);
      return;
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    if (video != null && video.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: video.value.size.width,
          height: video.value.size.height,
          child: VideoPlayer(video),
        ),
      );
    }
    for (final slot in widget.slots) {
      if (zImageProvider(slot) != null) return ZImage(slot);
    }
    return const SizedBox.shrink();
  }
}
