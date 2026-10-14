import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../services/z/power_level.dart';

// A power level as the scouter reads it: the digits spin at random for a
// moment, then lock onto the real value. Instant with "reduce motion".
class ScouterNumber extends StatefulWidget {
  const ScouterNumber({super.key, required this.value, required this.style, this.duration = const Duration(milliseconds: 900)});

  final int value;
  final TextStyle? style;
  final Duration duration;

  @override
  State<ScouterNumber> createState() => _ScouterNumberState();
}

class _ScouterNumberState extends State<ScouterNumber> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);
  final _random = math.Random();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.value > 0 || _controller.isAnimating) return;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ScouterNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !MediaQuery.of(context).disableAnimations) {
      _controller.forward(from: 0.4);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final String text;
        if (t >= 1) {
          text = formatPowerLevel(widget.value);
        } else if (t < 0.55) {
          final length = widget.value.toString().length;
          final scrambled = List.generate(length, (i) => i == 0 ? 1 + _random.nextInt(9) : _random.nextInt(10)).join();
          text = formatPowerLevel(int.parse(scrambled));
        } else {
          final eased = Curves.easeOutCubic.transform((t - 0.55) / 0.45);
          text = formatPowerLevel((widget.value * eased).round());
        }
        return Text(text, style: widget.style, maxLines: 1);
      },
    );
  }
}
