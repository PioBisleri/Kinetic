import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/plate_calculator.dart';

/// Visual barbell with the plates for [totalKg], mirrored around the bar.
/// Purely display: `totalKg` is already canonical.
class PlateBar extends StatelessWidget {
  const PlateBar({super.key, required this.totalKg, this.metric = true});

  final double totalKg;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    if (totalKg <= 0) return const SizedBox.shrink();

    final result = PlateCalculator.calculate(
      totalGrams: (totalKg * 1000).round(),
      metric: metric,
    );
    final plates = result.plates; // one side

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 52,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final p in plates.reversed) ...[
                  _plate(p, left: true),
                  const SizedBox(width: 2),
                ],
                _bar(context),
                for (final p in plates) ...[
                  const SizedBox(width: 2),
                  _plate(p, left: false),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Per side: ${PlateCalculator.pretty(plates, metric: metric)}'
          '${result.exact ? '' : ' · closest load'}',
          style: TextStyle(fontSize: 12, color: context.textSecondary),
        ),
      ],
    );
  }

  Widget _bar(BuildContext context) => Container(
        width: 8,
        height: 44,
        decoration: BoxDecoration(
          color: context.textTertiary,
          borderRadius: BorderRadius.circular(3),
        ),
      );

  Widget _plate(int grams, {required bool left}) {
    final kg = grams / 1000;
    // Thicker plates for heavier loads; teal family keeps brand cohesion.
    final lightness = (0.72 - (kg / 25) * 0.34).clamp(0.34, 0.72);
    final color = HSLColor.fromAHSL(1, 168, 0.55, lightness).toColor();
    final width = (10 + kg * 0.85).clamp(10.0, 34.0);

    return Container(
      width: width,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black26, width: 0.5),
        borderRadius: BorderRadius.horizontal(
          left: left ? const Radius.circular(4) : Radius.zero,
          right: left ? Radius.zero : const Radius.circular(4),
        ),
      ),
    );
  }
}
