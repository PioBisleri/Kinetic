import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tick meter for a value against a target — replaces the soft M3 progress
/// bar with a row of hard ledger segments.
class ProgressRule extends StatelessWidget {
  const ProgressRule({
    super.key,
    required this.value,
    this.segments = 14,
    this.height = 8,
    this.color,
  });

  /// 0..1 fraction complete.
  final double value;
  final int segments;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fraction = value.clamp(0.0, 1.0);
    final filled = fraction <= 0 ? 0 : (fraction * segments).ceil();
    final ink = color ?? context.accent;
    return Row(
      children: [
        for (var i = 0; i < segments; i++)
          Expanded(
            child: Container(
              height: height,
              margin: EdgeInsets.only(right: i == segments - 1 ? 0 : 2),
              decoration: BoxDecoration(
                color: i < filled ? ink : context.surfaceElevated,
                border: Border.all(color: i < filled ? ink : context.border),
              ),
            ),
          ),
      ],
    );
  }
}
