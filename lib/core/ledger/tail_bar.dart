import 'package:flutter/material.dart';

import '../navigation/shell_navigation.dart';
import '../theme/app_theme.dart';

/// App bar for the ledger pages: Bricolage title with an optional mono
/// subline (date, week, session state).
class TailBar extends StatelessWidget implements PreferredSizeWidget {
  const TailBar({
    super.key,
    required this.title,
    this.meta,
    this.actions,
    this.showMenu = true,
    this.leading,
    this.bottom,
  });

  final String title;
  final String? meta;
  final List<Widget>? actions;
  final bool showMenu;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(meta == null ? 56 : 68);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: meta == null ? 56 : 68,
      leading: showMenu ? const DrawerMenuButton() : leading,
      titleSpacing: showMenu || leading != null ? 0 : AppSpace.x5,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).appBarTheme.titleTextStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (meta != null) ...[
            const SizedBox(height: 2),
            Text(
              meta!.toUpperCase(),
              style: AppType.metaSm.copyWith(
                color: context.textTertiary,
                letterSpacing: 1.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
