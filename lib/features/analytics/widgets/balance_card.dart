import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../application/analytics_providers.dart';
import '../domain/grade_engine.dart';
import 'charts.dart';

/// Agonist vs antagonist volume ratios from the seed's balance pairs.
class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairs = ref.watch(balancePairsProvider).value;
    final window = ref.watch(muscleWindowProvider).value;

    if (pairs == null || window == null) {
      return const ChartCard(
        title: 'Balance',
        subtitle: 'agonist vs antagonist · 30-day volume',
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return ChartCard(
      title: 'Balance',
      subtitle: 'agonist vs antagonist · 30-day volume',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in pairs) ...[
            _BalanceRow(pair: p, window: window),
            if (p != pairs.last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.pair, required this.window});

  final BalancePairConfig pair;
  final Map<String, MuscleWindow> window;

  @override
  Widget build(BuildContext context) {
    final a = volumeOf(window, pair.aMuscles);
    final b = volumeOf(window, pair.bMuscles);
    final status = GradeEngine.balance(
      scoreA: a,
      scoreB: b,
      targetMin: pair.targetMin,
      targetMax: pair.targetMax,
    );
    final max = a > b ? a : b;
    final hasData = status.ratio != null;

    final ratioText = !hasData
        ? '—'
        : status.ratio! >= 999
            ? '∞'
            : '×${status.ratio!.toStringAsFixed(2)}';
    final ratioColor = !hasData
        ? context.textTertiary
        : status.isBalanced
            ? AppColors.gradeA
            : AppColors.heatWarm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                pair.name,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              ratioText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ratioColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _Bar(label: 'A', value: a, max: max, color: AppColors.accent),
        const SizedBox(height: 4),
        _Bar(label: 'B', value: b, max: max, color: AppColors.gradeB),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                hasData ? status.label : 'Log workouts to compare',
                style: TextStyle(
                  fontSize: 11,
                  color: hasData
                      ? (status.isBalanced
                          ? AppColors.gradeA
                          : AppColors.heatWarm)
                      : context.textTertiary,
                ),
              ),
            ),
            Text(
              'target ${_fmt(pair.targetMin)}–${_fmt(pair.targetMax)}',
              style: TextStyle(
                  fontSize: 10, color: context.textTertiary),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(double v) => v.toStringAsFixed(2);
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final String label;
  final double value;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(
            label,
            style:
                TextStyle(fontSize: 10, color: context.textTertiary),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: context.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: max <= 0 ? 0 : (value / max).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
