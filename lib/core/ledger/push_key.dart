import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Chunky equipment-key button: hard bottom edge, 3px press travel.
/// The physical, playful counterpart to the flat ledger surfaces.
class PushKey extends StatefulWidget {
  const PushKey({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.height = 56,
    this.icon,
    this.trailing,
    this.enabled = true,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final double height;
  final Widget? icon;
  final Widget? trailing;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<PushKey> createState() => _PushKeyState();
}

class _PushKeyState extends State<PushKey> {
  bool _down = false;

  bool get _enabled => widget.enabled && widget.onPressed != null;

  void _setDown(bool value) {
    if (!_enabled || _down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? context.accent;
    final edge = Color.lerp(accent, Colors.black, 0.42)!;
    final ink = onAccent(accent);
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setDown(true),
        onTapUp: (_) => _setDown(false),
        onTapCancel: () => _setDown(false),
        onTap: _enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onPressed!.call();
              }
            : null,
        child: SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 3,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _enabled ? edge : edge.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: AppMotion.fast,
                curve: AppMotion.curve,
                left: 0,
                right: 0,
                top: _down ? 3 : 0,
                bottom: _down ? 0 : 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _enabled ? accent : accent.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            IconTheme(
                              data: IconThemeData(color: ink, size: 18),
                              child: widget.icon!,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                            child: Text(
                              widget.label,
                              style: AppType.button.copyWith(
                                color: ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.trailing != null) ...[
                            const SizedBox(width: 10),
                            widget.trailing!,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
