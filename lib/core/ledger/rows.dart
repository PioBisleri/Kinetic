import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ledger line: label left, tabular value right, hairline underneath.
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.unit,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.divider = true,
    this.dense = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? sub;
  final String? unit;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool divider;
  final bool dense;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 9 : 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppType.bodySm.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!.toUpperCase(),
                    style: AppType.metaSm.copyWith(color: context.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
          Text.rich(
            TextSpan(
              text: value,
              style: AppType.data.copyWith(
                color: valueColor ?? context.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              children: [
                if (unit != null && unit!.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: AppType.metaSm.copyWith(color: context.textTertiary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: context.accent.withValues(alpha: 0.06),
        highlightColor: context.accent.withValues(alpha: 0.04),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: divider
                ? Border(bottom: BorderSide(color: context.border))
                : null,
          ),
          child: row,
        ),
      ),
    );
  }
}

/// Single readout: meta label over a large tabular value.
class Metric extends StatelessWidget {
  const Metric({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.valueStyle,
    this.delta,
    this.deltaUp = true,
    this.color,
    this.alignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final String? unit;
  final TextStyle? valueStyle;
  final String? delta;
  final bool deltaUp;
  final Color? color;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppType.meta.copyWith(color: context.textTertiary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value,
                style: (valueStyle ?? AppType.dataXl).copyWith(
                  color: color ?? context.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unit != null && unit!.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                unit!,
                style: AppType.metaSm.copyWith(color: context.textTertiary),
              ),
            ],
            if (delta != null) ...[
              const SizedBox(width: 8),
              SignalChip(text: delta!, up: deltaUp),
            ],
          ],
        ),
      ],
    );
  }
}

/// Horizontal metric strip separated by hairlines — no card fills.
class StatBlocks extends StatelessWidget {
  const StatBlocks({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpace.x4),
    this.divider = true,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0 && divider) {
        rows.add(Container(width: 1, color: context.border));
      }
      rows.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x3),
            child: children[i],
          ),
        ),
      );
    }
    return IntrinsicHeight(
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
  }
}

/// Warm ember delta chip ('▲ 12%') reserved for records and movement.
class SignalChip extends StatelessWidget {
  const SignalChip({super.key, required this.text, this.up = true, this.color});

  final String text;
  final bool up;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.signal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        border: Border.all(color: tint.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(AppRadius.data),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(6, 6),
            painter: _ArrowPainter(up: up, color: tint),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppType.metaSm.copyWith(
              color: tint,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.up, required this.color});

  final bool up;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    final path = Path();
    if (up) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.up != up || old.color != color;
}
