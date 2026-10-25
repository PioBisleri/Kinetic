import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glyphs.dart';

/// Custom bottom navigation: hairline top rule, square glyphs, mono
/// uppercase labels and a 2px accent underline on the active tab.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const labels = ['Home', 'Routines', 'Analytics', 'History', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: _NavCell(
                    index: i,
                    label: labels[i],
                    active: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.index,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = active ? context.accent : context.textSecondary;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        key: Key('nav-$index'),
        onTap: onTap,
        splashColor: context.accent.withValues(alpha: 0.06),
        highlightColor: context.accent.withValues(alpha: 0.04),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 14,
              right: 14,
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.curve,
                height: 2,
                color: active ? context.accent : Colors.transparent,
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LedgerGlyph(
                    tabGlyph(index),
                    size: 19,
                    color: tint,
                    strokeWidth: active ? 2 : 1.5,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: AppType.meta.copyWith(
                      fontSize: 9,
                      letterSpacing: 1.0,
                      color: tint,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
