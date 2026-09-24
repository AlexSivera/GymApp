import 'package:flutter/material.dart';

// A number that counts up to [value] the first time it's shown (and eases to
// any new value after that), for the handful of stats worth a little moment:
// streak, today's calories, a finished session's volume. Jumps straight to
// the value with "reduce motion" on.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.textAlign,
  });

  final double value;
  final String Function(double value) format;
  final TextStyle? style;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Text(format(value), style: style, textAlign: textAlign);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => Text(format(animated), style: style, textAlign: textAlign),
    );
  }
}
