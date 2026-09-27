import 'package:flutter/material.dart';

import '../../../core/settings/settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weight_units.dart';
import '../domain/suggestion_engine.dart';

/// The chip's "i" → the full double-progression rules with the rule that
/// produced *this* suggestion highlighted.
Future<void> showSuggestionWhySheet(
  BuildContext context, {
  required Suggestion suggestion,
  required UnitSystem unit,
}) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      builder: (_) => _SuggestionWhySheet(suggestion: suggestion, unit: unit),
    );

class _SuggestionWhySheet extends StatelessWidget {
  const _SuggestionWhySheet({required this.suggestion, required this.unit});

  final Suggestion suggestion;
  final UnitSystem unit;

  static const _rules = [
    (
      SuggestionAction.start,
      Icons.flag_rounded,
      'Start',
      "No history yet — the set opens at the routine's planned weight.",
    ),
    (
      SuggestionAction.progress,
      Icons.arrow_upward_rounded,
      'Progress',
      'You hit the rep target, so the weight earns one increment.',
    ),
    (
      SuggestionAction.repeat,
      Icons.repeat_rounded,
      'Repeat',
      'Hold the weight until you own the reps for the full range.',
    ),
    (
      SuggestionAction.deload,
      Icons.arrow_downward_rounded,
      'Deload',
      'Stalled at the same weight — reset about 10% and build back up.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final lbl = unitLabel(unit);
    final step = formatWeight(stepKg(unit), unit);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Why this suggestion?',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${formatWeight(suggestion.weightKg, unit)} $lbl'
                    ' · ${suggestion.reason}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Double progression — the four rules, in order:',
              style: TextStyle(fontSize: 12, color: context.textTertiary),
            ),
            const SizedBox(height: 4),
            for (final (action, icon, title, body) in _rules) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: action == suggestion.action
                          ? AppColors.accent
                          : context.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: action == suggestion.action
                                  ? AppColors.accent
                                  : context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            body,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: context.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'History uses the top set of each prior session · '
              'increments are $step $lbl per the unit setting.',
              style: TextStyle(fontSize: 11, color: context.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
