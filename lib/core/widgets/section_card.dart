import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Titled block of list rows — the visual unit Profile and Settings are
/// built from: uppercase caption (with an optional leading icon) above a
/// card of tiles.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.iconColor,
  });

  final String title;
  final List<Widget> children;

  /// Optional 20 px icon left of the caption — section identity for the
  /// longer pages (Settings, Profile).
  final IconData? icon;

  /// Overrides [context.accent] for the icon tint (e.g. the danger zone).
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: iconColor ?? context.accent),
                const SizedBox(width: 6),
              ],
              Text(
                title.toUpperCase(),
                style:
                    (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
                        .copyWith(color: context.textTertiary),
              ),
            ],
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}
