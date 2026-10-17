import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Round 9 (F2) — the one empty-state idiom: quiet Card, centered copy.
/// `message` is the primary line; `secondary` (optional hint) renders
/// smaller and dimmer beneath it.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.secondary,
    this.padding = const EdgeInsets.all(20),
  });

  final String message;
  final String? secondary;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppStyles.body
                    .copyWith(color: context.textSecondary),
              ),
              if (secondary != null) ...[
                const SizedBox(height: 4),
                Text(
                  secondary!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: context.textTertiary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
