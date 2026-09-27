import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_providers.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/weight_units.dart';
import 'weight_trend.dart';

/// The weight-trend bottom sheet (Round 6): current / 7-day average /
/// change over the window, then the raw series with its trailing
/// 7-day average drawn through it.
Future<void> showWeightTrendSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      builder: (_) => const WeightTrendSheet(),
    );

class WeightTrendSheet extends ConsumerWidget {
  const WeightTrendSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(settingsProvider).unit;
    final rows = ref.watch(bodyMetricsProvider).value ?? const [];
    final points = trendPoints(rows, DateTime.now());
    final lbl = unitLabel(unit);

    final avg = points.isEmpty ? null : trailingAvg(points, DateTime.now());
    final delta = trendDelta(points);

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
              'Weight trend',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'last $weightTrendWeeks weeks · one point per weigh-in',
              style: TextStyle(fontSize: 12, color: context.textTertiary),
            ),
            const SizedBox(height: 16),
            if (points.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No weigh-ins in this window yet.\n'
                    'Save a weight under Your data to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: context.textTertiary),
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  _TrendStat(
                    label: 'Current',
                    value:
                        '${formatWeight(points.last.weightKg, unit)} $lbl',
                  ),
                  _TrendStat(
                    label: '7-day avg',
                    value: avg == null ? '—' : '${formatWeight(avg, unit)} $lbl',
                  ),
                  _TrendStat(
                    label: 'Change',
                    value: delta == null
                        ? '—'
                        : '${delta >= 0 ? '+' : '-'}'
                            '${formatWeight(delta.abs(), unit)} $lbl',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: _TrendChart(points: points, unit: unit),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _LegendSwatch(color: AppColors.accent, label: 'Weigh-in'),
                  const SizedBox(width: 12),
                  _LegendSwatch(
                    color: context.textTertiary,
                    label: '7-day average',
                    dashed: true,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Points appear when you save a weight in Your data — '
              'one per day, corrections included.',
              style: TextStyle(fontSize: 11, color: context.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendStat extends StatelessWidget {
  const _TrendStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed)
          for (var i = 0; i < 3; i++) ...[
            Container(width: 4, height: 3, color: color),
            if (i < 2) const SizedBox(width: 2),
          ]
        else
          Container(width: 14, height: 3, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: context.textTertiary),
        ),
      ],
    );
  }
}

/// Raw weigh-ins (accent line, dots) with the trailing 7-day average
/// drawn through them (hairline, dashed). x = days since the first
/// point; y = display units.
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points, required this.unit});

  final List<TrendPoint> points;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    final since = points.first.day;
    int xOf(DateTime day) => day.difference(since).inDays;

    final raw = [
      for (final p in points)
        FlSpot(xOf(p.day).toDouble(), kgToDisplay(p.weightKg, unit)),
    ];
    final avgSpots = <FlSpot>[];
    for (final p in points) {
      final avg = trailingAvg(points, p.day);
      if (avg != null) {
        avgSpots.add(FlSpot(xOf(p.day).toDouble(), kgToDisplay(avg, unit)));
      }
    }

    var lo = raw.first.y;
    var hi = raw.first.y;
    for (final s in raw) {
      if (s.y < lo) lo = s.y;
      if (s.y > hi) hi = s.y;
    }
    for (final s in avgSpots) {
      if (s.y < lo) lo = s.y;
      if (s.y > hi) hi = s.y;
    }
    final pad = ((hi - lo) * 0.2).clamp(0.5, 5.0).toDouble();
    final minY = lo - pad;
    final maxY = hi + pad;

    final maxX = raw.last.x < 6 ? 6.0 : raw.last.x;
    final labelStep = (maxX / 3).round().clamp(1, 1 << 30).toInt();
    final lbl = unitLabel(unit);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: raw,
            isCurved: false,
            barWidth: 2,
            color: AppColors.accent,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.accent.withValues(alpha: 0.18),
                  AppColors.accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          if (avgSpots.length > 1)
            LineChartBarData(
              spots: avgSpots,
              isCurved: false,
              barWidth: 1.5,
              dashArray: const [4, 4],
              color: context.textTertiary,
              dotData: const FlDotData(show: false),
            ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 2,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: context.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => context.surfaceElevated,
            getTooltipItems: (touched) => [
              for (final t in touched)
                LineTooltipItem(
                  // y is already in display units (spots are built that way).
                  '${t.barIndex == 1 ? 'avg ' : ''}'
                  '${_pretty(t.y)} $lbl\n'
                  '${_dateLabel(since.add(Duration(days: t.x.round())))}',
                  TextStyle(
                    color: context.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: (maxY - minY) / 2,
              getTitlesWidget: (v, meta) => Text(
                v == v.roundToDouble()
                    ? v.toStringAsFixed(0)
                    : v.toStringAsFixed(1),
                style: TextStyle(fontSize: 10, color: context.textTertiary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: labelStep.toDouble(), // whole-day ticks only
              getTitlesWidget: (v, meta) {
                final x = v.round();
                if (x != 0 && x % labelStep != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _dateLabel(since.add(Duration(days: x))),
                    style:
                        TextStyle(fontSize: 10, color: context.textTertiary),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 250),
    );
  }
}

String _dateLabel(DateTime d) => '${d.day}/${d.month}';

/// Display-unit number, one decimal at most ('82', '82.5').
String _pretty(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
