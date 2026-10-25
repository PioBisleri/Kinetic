import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ink-stamp motif: rotated double-ruled mono label. Used for PRs, grades
/// and milestone marks — the playful layer of the ledger.
class Stamp extends StatelessWidget {
  const Stamp(
    this.text, {
    super.key,
    this.color,
    this.rotate = true,
    this.fontSize = 9,
  });

  final String text;
  final Color? color;
  final bool rotate;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.signal;
    final mark = Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        border: Border.all(color: tint.withValues(alpha: 0.75), width: 1.4),
        borderRadius: BorderRadius.circular(AppRadius.data),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: tint.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(1),
        ),
        child: Text(
          text.toUpperCase(),
          style: AppType.meta.copyWith(
            color: tint,
            fontSize: fontSize,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ),
    );
    if (!rotate) return mark;
    return Transform.rotate(angle: -0.087, child: mark);
  }
}

/// Streak tally marks — four uprights plus a slash per group of five.
class Tally extends StatelessWidget {
  const Tally({
    super.key,
    required this.count,
    this.color,
    this.height = 14,
    this.strokeWidth = 1.6,
  });

  final int count;
  final Color? color;
  final double height;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final groups = count ~/ 5;
    final rem = count % 5;
    final width = groups * 34.0 + rem * 7.0;
    return SizedBox(
      width: math.max(width, 1),
      height: height,
      child: CustomPaint(
        painter: _TallyPainter(
          count: count,
          color: color ?? context.signal,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _TallyPainter extends CustomPainter {
  _TallyPainter({
    required this.count,
    required this.color,
    required this.strokeWidth,
  });

  final int count;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;
    final groups = count ~/ 5;
    final rem = count % 5;
    for (var g = 0; g < groups; g++) {
      final x0 = g * 34.0;
      for (var i = 0; i < 4; i++) {
        final x = x0 + i * 7.0;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      canvas.drawLine(Offset(x0 - 3, size.height), Offset(x0 + 24, 0), paint);
    }
    final base = groups * 34.0;
    for (var i = 0; i < rem; i++) {
      final x = base + i * 7.0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_TallyPainter old) =>
      old.count != count ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
