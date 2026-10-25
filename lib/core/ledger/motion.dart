import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tabular number that counts from its previous value to the new one.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 450),
    this.alignment = TextAlign.start,
  });

  final double value;
  final String Function(double) format;
  final TextStyle? style;
  final Duration duration;
  final TextAlign alignment;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: duration,
      curve: AppMotion.curve,
      builder: (context, animated, _) => Text(
        format(animated),
        style: style,
        textAlign: alignment,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
