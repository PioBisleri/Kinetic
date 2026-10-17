import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Round 9 (F2) — shared interaction shells. One exit for confirm dialogs
/// and snackbars so every page speaks the same idiom.

/// Standard confirm/cancel `AlertDialog`. Safe default is the neutral
/// confirm; pass `danger: true` for destructive confirms (red button).
///
/// Returns true only when the user tapped the confirm label.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool danger = false,
  Key? confirmKey,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          key: confirmKey ?? const Key('confirm-action-yes'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            backgroundColor: danger ? dialogContext.danger : null,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Floating snack with the app's standard look (theme supplies colors);
/// optional undo callback mirrors the water +250/-250 pattern.
///
/// Always `persist: false`: Flutter 3.38 changed the default so snackbars
/// with an action never auto-dismiss — the opposite of what a quick-log
/// undo wants (the user dismissed it as a bug: "the undo option persists").
void showSnack(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: action,
      persist: false,
    ),
  );
}

/// The one bottom-sheet chrome: `context.surface` background with the
/// 6px top-radius sheet dent. Pass `isScrollControlled` for keyboard
/// covering input sheets.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    backgroundColor: context.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
    ),
    builder: builder,
  );
}
