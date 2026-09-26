import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key for the shell [Scaffold] that hosts the app drawer. Provided per
/// container (not a global) so two apps mounted in one test container can
/// never fight over the same GlobalKey.
final shellScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>(
  (ref) => GlobalKey<ScaffoldState>(),
);

/// Hamburger button for the tab AppBars. Each tab builds its own nested
/// Scaffold, so `Scaffold.of(context)` would find that one (no drawer);
/// the key points at the shell scaffold that actually owns the drawer.
class DrawerMenuButton extends ConsumerWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: 'Menu',
      onPressed: () =>
          ref.read(shellScaffoldKeyProvider).currentState?.openDrawer(),
    );
  }
}
