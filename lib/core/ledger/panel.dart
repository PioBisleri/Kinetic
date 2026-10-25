import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Hairline rule — the primary separator in the ledger language.
class Rule extends StatelessWidget {
  const Rule({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.color,
    this.thickness = 1,
  });

  final double indent;
  final double endIndent;
  final Color? color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: thickness,
      margin: EdgeInsets.only(left: indent, right: endIndent),
      color: color ?? context.border,
    );
  }
}

/// Subtle dot-grid paper, painted behind panel content.
class DotGrid extends StatelessWidget {
  const DotGrid({
    super.key,
    required this.child,
    this.spacing = 12,
    this.color,
  });

  final Widget child;
  final double spacing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotGridPainter(
        spacing: spacing,
        color: (color ?? context.border).withValues(alpha: 0.55),
      ),
      child: child,
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({required this.spacing, required this.color});

  final double spacing;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) =>
      old.spacing != spacing || old.color != color;
}

/// The ledger's structural block: hairline border, 2px radius, optional
/// indexed header and dot-grid paper. Replaces the floating card.
class LedgerPanel extends StatelessWidget {
  const LedgerPanel({
    super.key,
    this.title,
    this.index,
    this.meta,
    this.action,
    this.child,
    this.padding = const EdgeInsets.all(AppSpace.x4),
    this.grid = false,
    this.accentTop = false,
    this.dense = false,
  });

  final String? title;

  /// Two-digit section index shown before the title ('04').
  final String? index;
  final String? meta;
  final Widget? action;
  final Widget? child;
  final EdgeInsets padding;
  final bool grid;
  final bool accentTop;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null;
    final content = Padding(padding: padding, child: child);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.data),
        border: Border.all(color: context.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (accentTop) Container(height: 2, color: context.accent),
            if (hasHeader) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  dense ? 8 : 10,
                  14,
                  dense ? 8 : 10,
                ),
                child: Row(
                  children: [
                    if (index != null) ...[
                      Text(
                        index!,
                        style: AppType.meta.copyWith(
                          color: context.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 12,
                        height: 1,
                        color: context.textTertiary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title!.toUpperCase(),
                        style: AppType.meta.copyWith(
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (meta != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        meta!,
                        style: AppType.metaSm.copyWith(
                          color: context.textTertiary,
                        ),
                      ),
                    ],
                    if (action != null) ...[const SizedBox(width: 8), action!],
                  ],
                ),
              ),
              Rule(),
            ],
            if (grid) DotGrid(child: content) else content,
          ],
        ),
      ),
    );
  }
}

/// Section label row — '04 — VOLUME' plus optional trailing meta and a
/// small ember diamond when the section holds a record.
class SectionHead extends StatelessWidget {
  const SectionHead({
    super.key,
    this.index,
    required this.title,
    this.meta,
    this.record = false,
    this.action,
  });

  final String? index;
  final String title;
  final String? meta;
  final bool record;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (index != null) ...[
          Text(
            index!,
            style: AppType.meta.copyWith(color: context.textTertiary),
          ),
          const SizedBox(width: 8),
          Container(
            width: 14,
            height: 1,
            color: context.textTertiary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          flex: 3,
          child: Text(
            title.toUpperCase(),
            style: AppType.meta.copyWith(
              color: context.textPrimary,
              letterSpacing: 1.8,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (record) ...[
          const SizedBox(width: 8),
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(width: 5, height: 5, color: context.signal),
          ),
        ],
        if (meta != null) ...[
          const SizedBox(width: 10),
          Expanded(child: Rule()),
          const SizedBox(width: 10),
          Text(
            meta!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.metaSm.copyWith(color: context.textTertiary),
          ),
        ],
        if (action != null) ...[const SizedBox(width: 10), action!],
      ],
    );
  }
}

/// Chapter opener for long pages — big Bricolage title with a mono index
/// and hairline. One per thematic block (Analytics' Training/Muscle/Balance).
class ChapterHead extends StatelessWidget {
  const ChapterHead({
    super.key,
    this.index,
    required this.title,
    this.meta,
    this.action,
  });

  final String? index;
  final String title;
  final String? meta;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (index != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  index!,
                  style: AppType.meta.copyWith(color: context.textTertiary),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: 20,
                  height: 1,
                  color: context.textTertiary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.h1.copyWith(color: context.textPrimary),
              ),
            ),
            if (action != null) ...[const SizedBox(width: 8), action!],
          ],
        ),
        if (meta != null) ...[
          const SizedBox(height: 3),
          Text(
            meta!.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.metaSm.copyWith(color: context.textTertiary),
          ),
        ],
        const SizedBox(height: 8),
        Rule(),
      ],
    );
  }
}

/// Ledger-cased group for list-style content (Profile/Settings). Replaces
/// the old SectionCard: mono caption, panel, hairlines between rows.
class LedgerGroup extends StatelessWidget {
  const LedgerGroup({
    super.key,
    this.index,
    required this.title,
    this.meta,
    this.action,
    required this.children,
    this.divided = true,
  });

  final String? index;
  final String title;
  final String? meta;
  final Widget? action;
  final List<Widget> children;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(index: index, title: title, meta: meta, action: action),
        const SizedBox(height: AppSpace.x3),
        LedgerPanel(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (divided && i > 0) const Rule(),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
