import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum LedgerGlyphType {
  home,
  routines,
  analytics,
  history,
  profile,
  play,
  timer,
  check,
  chevronLeft,
  chevronRight,
  chevronDown,
  plus,
  menu,
  info,
  search,
  close,
  edit,
  trash,
}

/// Hand-drawn icon set for the ledger language: 24px grid, square caps,
/// squared joins — no stock Material outlines.
class LedgerGlyph extends StatelessWidget {
  const LedgerGlyph(
    this.type, {
    super.key,
    this.size = 22,
    this.color,
    this.strokeWidth = 1.6,
  });

  final LedgerGlyphType type;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GlyphPainter(
          type: type,
          color: color ?? context.textSecondary,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

LedgerGlyphType tabGlyph(int index) => switch (index) {
  0 => LedgerGlyphType.home,
  1 => LedgerGlyphType.routines,
  2 => LedgerGlyphType.analytics,
  3 => LedgerGlyphType.history,
  _ => LedgerGlyphType.profile,
};

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({
    required this.type,
    required this.color,
    required this.strokeWidth,
  });

  final LedgerGlyphType type;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    switch (type) {
      case LedgerGlyphType.home:
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 10.5)
            ..lineTo(12, 3.5)
            ..lineTo(20.5, 10.5),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(5.5, 10)
            ..lineTo(5.5, 20)
            ..lineTo(18.5, 20)
            ..lineTo(18.5, 10),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(10, 20)
            ..lineTo(10, 14.5)
            ..lineTo(14, 14.5)
            ..lineTo(14, 20),
          paint,
        );
      case LedgerGlyphType.routines:
        for (final y in [6.5, 12.0, 17.5]) {
          canvas.drawRect(Rect.fromLTWH(3.5, y - 1.5, 3, 3), paint);
          canvas.drawLine(Offset(9.5, y), Offset(20.5, y), paint);
        }
      case LedgerGlyphType.analytics:
        canvas.drawLine(const Offset(4, 19.5), const Offset(20, 19.5), paint);
        canvas.drawLine(const Offset(7, 19.5), const Offset(7, 13), paint);
        canvas.drawLine(const Offset(12, 19.5), const Offset(12, 7.5), paint);
        canvas.drawLine(const Offset(17, 19.5), const Offset(17, 11), paint);
      case LedgerGlyphType.history:
        canvas.drawCircle(const Offset(12, 12.5), 7.5, paint);
        canvas.drawLine(const Offset(12, 12.5), const Offset(12, 8), paint);
        canvas.drawLine(const Offset(12, 12.5), const Offset(15.5, 14), paint);
      case LedgerGlyphType.profile:
        canvas.drawCircle(const Offset(12, 8), 3.4, paint);
        canvas.drawPath(
          Path()
            ..moveTo(4.5, 20.5)
            ..cubicTo(4.5, 15.5, 8, 14, 12, 14)
            ..cubicTo(16, 14, 19.5, 15.5, 19.5, 20.5),
          paint,
        );
      case LedgerGlyphType.play:
        canvas.drawPath(
          Path()
            ..moveTo(8, 4.5)
            ..lineTo(19, 12)
            ..lineTo(8, 19.5)
            ..close(),
          paint,
        );
      case LedgerGlyphType.timer:
        canvas.drawCircle(const Offset(12, 13.5), 7, paint);
        canvas.drawLine(const Offset(12, 3.5), const Offset(12, 6.5), paint);
        canvas.drawLine(const Offset(12, 13.5), const Offset(12, 9), paint);
        canvas.drawLine(
          const Offset(12, 13.5),
          const Offset(15.5, 13.5),
          paint,
        );
      case LedgerGlyphType.check:
        canvas.drawPath(
          Path()
            ..moveTo(4.5, 12.5)
            ..lineTo(9.5, 17.5)
            ..lineTo(19.5, 6.5),
          paint,
        );
      case LedgerGlyphType.chevronLeft:
        canvas.drawPath(
          Path()
            ..moveTo(14.5, 5.5)
            ..lineTo(8, 12)
            ..lineTo(14.5, 18.5),
          paint,
        );
      case LedgerGlyphType.chevronRight:
        canvas.drawPath(
          Path()
            ..moveTo(9.5, 5.5)
            ..lineTo(16, 12)
            ..lineTo(9.5, 18.5),
          paint,
        );
      case LedgerGlyphType.chevronDown:
        canvas.drawPath(
          Path()
            ..moveTo(5.5, 9)
            ..lineTo(12, 15.5)
            ..lineTo(18.5, 9),
          paint,
        );
      case LedgerGlyphType.plus:
        canvas.drawLine(const Offset(12, 4.5), const Offset(12, 19.5), paint);
        canvas.drawLine(const Offset(4.5, 12), const Offset(19.5, 12), paint);
      case LedgerGlyphType.menu:
        for (final y in [6.5, 12.0, 17.5]) {
          canvas.drawLine(Offset(3.5, y), Offset(20.5, y), paint);
        }
      case LedgerGlyphType.info:
        canvas.drawCircle(const Offset(12, 12), 8, paint);
        canvas.drawRect(
          Rect.fromLTWH(11, 6.8, 2, 2),
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
        canvas.drawLine(const Offset(12, 11), const Offset(12, 16.5), paint);
      case LedgerGlyphType.search:
        canvas.drawCircle(const Offset(10.5, 10.5), 5.5, paint);
        canvas.drawLine(const Offset(14.6, 14.6), const Offset(20, 20), paint);
      case LedgerGlyphType.close:
        canvas.drawLine(const Offset(6, 6), const Offset(18, 18), paint);
        canvas.drawLine(const Offset(18, 6), const Offset(6, 18), paint);
      case LedgerGlyphType.edit:
        canvas.drawPath(
          Path()
            ..moveTo(4.5, 19.5)
            ..lineTo(5.2, 15.2)
            ..lineTo(16.7, 3.7)
            ..lineTo(20.3, 7.3)
            ..lineTo(8.8, 18.8)
            ..close(),
          paint,
        );
        canvas.drawLine(
          const Offset(14.5, 5.9),
          const Offset(18.1, 9.5),
          paint,
        );
      case LedgerGlyphType.trash:
        canvas.drawLine(const Offset(4, 7), const Offset(20, 7), paint);
        canvas.drawLine(const Offset(9, 4.5), const Offset(15, 4.5), paint);
        canvas.drawPath(
          Path()
            ..moveTo(6, 7)
            ..lineTo(7.5, 20)
            ..lineTo(16.5, 20)
            ..lineTo(18, 7),
          paint,
        );
        canvas.drawLine(const Offset(10, 10.5), const Offset(10, 16.5), paint);
        canvas.drawLine(const Offset(14, 10.5), const Offset(14, 16.5), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.type != type || old.color != color || old.strokeWidth != strokeWidth;
}
