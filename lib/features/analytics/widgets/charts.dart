import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/settings/settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weight_units.dart';
import '../application/analytics_providers.dart';
import '../domain/analytics_math.dart';

TextStyle _axisStyle(BuildContext context) =>
    TextStyle(fontSize: 10, color: context.textTertiary);

String _unitLabel(UnitSystem u) => u == UnitSystem.lbs ? 'lb' : 'kg';

/// Shared card chrome: title + caption + child, on any Analytics chart.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(subtitle,
                style:
                    TextStyle(fontSize: 12, color: context.textSecondary)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// 4W / 12W / 6M / All window selector.
class PeriodChips extends ConsumerWidget {
  const PeriodChips({super.key});

  /// `0` = All history (see [periodStart]).
  static const _options = [(4, '4W'), (12, '12W'), (26, '6M'), (0, 'All')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeks = ref.watch(analyticsPeriodProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (w, label) in _options)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              key: Key('period-$w'),
              label: Text(label),
              selected: weeks == w,
              onSelected: (_) =>
                  ref.read(analyticsPeriodProvider.notifier).set(w),
            ),
          ),
      ],
    );
  }
}

/// Three headline numbers: workouts, streak, volume.
class StatsRow extends StatelessWidget {
  const StatsRow({
    super.key,
    required this.workoutCount,
    required this.streakWeeks,
    required this.volumeKg,
    required this.unit,
  });

  final int workoutCount;
  final int streakWeeks;
  final double volumeKg;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            _Stat(
              valueKey: const Key('stat-workouts'),
              value: '$workoutCount',
              label: 'Workouts',
              style: style,
            ),
            _Stat(
              valueKey: const Key('stat-streak'),
              value: '${streakWeeks}w',
              label: 'Streak',
              style: style,
            ),
            _Stat(
              valueKey: const Key('stat-volume'),
              value:
                  '${compactNumber(kgToDisplay(volumeKg, unit))} ${_unitLabel(unit)}',
              label: 'Volume',
              style: style,
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.valueKey,
    required this.value,
    required this.label,
    required this.style,
  });

  final Key valueKey;
  final String value;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            key: valueKey,
            style: style?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: context.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Weekly working-volume bars, in display units.
class WeeklyVolumeChart extends StatelessWidget {
  const WeeklyVolumeChart({
    super.key,
    required this.points,
    required this.unit,
  });

  final List<WeekPoint> points;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    final display = [for (final p in points) kgToDisplay(p.volumeKg, unit)];
    var peak = 0.0;
    for (final v in display) {
      if (v > peak) peak = v;
    }
    final maxY = peak <= 0 ? 100.0 : peak * 1.25;
    // "All" can span 100+ weeks — slim the rods so they never overlap.
    final rodWidth = points.length > 52
        ? 4.0
        : points.length > 26
            ? 8.0
            : 14.0;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: display[i],
                  width: rodWidth,
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ]),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 2,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: context.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (g) => context.surfaceElevated,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final p = points[group.x];
                return BarTooltipItem(
                  '${compactNumber(rod.toY)} ${_unitLabel(unit)}\n'
                  '${p.weekStart.day}/${p.weekStart.month}',
                  TextStyle(
                    color: context.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, meta) =>
                    Text(compactNumber(v), style: _axisStyle(context)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  // Keep ~8 labels on screen no matter the window size.
                  final every = (points.length / 8).ceil().clamp(1, 1 << 30);
                  if (i % every != 0) return const SizedBox.shrink();
                  final d = points[i].weekStart;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${d.day}/${d.month}', style: _axisStyle(context)),
                  );
                },
              ),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}

/// Which day-level series an [ExerciseTrendChart] plots.
enum ExerciseSeries { e1rm, volume }

/// Estimated-1RM (or daily-volume) progression for one exercise.
class ExerciseTrendChart extends StatelessWidget {
  const ExerciseTrendChart({
    super.key,
    required this.rows,
    required this.since,
    required this.unit,
    this.series = ExerciseSeries.e1rm,
  });

  final List<ExerciseHistoryData> rows;
  final DateTime since; // window start — maps dates to x positions
  final UnitSystem unit;
  final ExerciseSeries series;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (final r in rows) {
      final v = series == ExerciseSeries.e1rm ? r.bestE1Rm : r.totalVolume;
      if (v <= 0) continue;
      spots.add(FlSpot(
        daysBetween(since, r.date).toDouble(),
        kgToDisplay(v, unit),
      ));
    }
    spots.sort((a, b) => a.x.compareTo(b.x));

    if (spots.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            series == ExerciseSeries.e1rm
                ? 'No strength data in this window.'
                : 'No volume data in this window.',
            style: TextStyle(fontSize: 12, color: context.textTertiary),
          ),
        ),
      );
    }

    var peak = 0.0;
    for (final s in spots) {
      if (s.y > peak) peak = s.y;
    }
    final maxY = peak * 1.2;
    final maxX = spots.last.x < 6 ? 6.0 : spots.last.x;
    final labelStep = (maxX / 3).round().clamp(1, 1 << 30).toInt();

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 2.5,
              color: AppColors.accent,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.accent.withValues(alpha: 0.28),
                    AppColors.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 2,
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
                    '${series == ExerciseSeries.e1rm ? t.y.toStringAsFixed(1) : compactNumber(t.y)} '
                    '${_unitLabel(unit)}\n'
                    '${_dateLabel(addDays(since, t.x.round()))}',
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
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, meta) =>
                    Text(compactNumber(v), style: _axisStyle(context)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, meta) {
                  final x = v.round();
                  if (x != 0 && x % labelStep != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child:
                        Text(_dateLabel(addDays(since, x)), style: _axisStyle(context)),
                  );
                },
              ),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}

String _dateLabel(DateTime d) => '${d.day}/${d.month}';

/// GitHub-style grid of trained days: 7 columns (Mon–Sun), [rows] weeks
/// ending with the current week.
class ConsistencyCalendar extends StatelessWidget {
  const ConsistencyCalendar({
    super.key,
    required this.days,
    required this.now,
    this.rows = 12,
  });

  final Set<DateTime> days;
  final DateTime now;

  /// How many week rows to draw (one row per Monday-start week).
  final int rows;

  @override
  Widget build(BuildContext context) {
    final today = dayOf(now);
    final firstWeek = addDays(weekStartOf(today), -7 * (rows - 1));

    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final l in letters)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: SizedBox(
                  width: 14,
                  child: Center(
                    child: Text(
                      l,
                      style: TextStyle(
                          fontSize: 9, color: context.textTertiary),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var w = 0; w < rows; w++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (var dow = 0; dow < 7; dow++)
                  _CalendarCell(
                    day: addDays(firstWeek, 7 * w + dow),
                    today: today,
                    trained: days.contains(addDays(firstWeek, 7 * w + dow)),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            _LegendDot(color: AppColors.accent, label: 'Trained'),
            SizedBox(width: 12),
            _LegendDot(color: context.surfaceElevated, label: 'Rest'),
          ],
        ),
      ],
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.today,
    required this.trained,
  });

  final DateTime day;
  final DateTime today;
  final bool trained;

  @override
  Widget build(BuildContext context) {
    final future = day.isAfter(today);
    final color = future
        ? context.background
        : trained
            ? AppColors.accent
            : context.surfaceElevated;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        key: ValueKey('cal-${day.millisecondsSinceEpoch}'),
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: context.textTertiary),
        ),
      ],
    );
  }
}

/// Strength card: exercise picker + e1RM trend (watches its own providers).
class StrengthCard extends ConsumerWidget {
  const StrengthCard({
    super.key,
    required this.weeks,
    required this.unit,
    required this.windowStart,
  });

  final int weeks;
  final UnitSystem unit;
  final DateTime windowStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(historyExercisesProvider(weeks));
    final exercises = exercisesAsync.value ?? const <Exercise>[];
    final selected = ref.watch(selectedExerciseProvider);

    final String? effective = exercises.isEmpty
        ? null
        : exercises.any((e) => e.id == selected)
            ? selected
            : exercises.first.id;

    return ChartCard(
      title: 'Strength',
      subtitle: 'estimated 1RM progression (Epley)',
      child: exercisesAsync.isLoading && exercises.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          : exercises.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No weighted sets logged in this window.',
                      style: TextStyle(
                          fontSize: 12, color: context.textTertiary),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<String>(
                      key: const Key('exercise-picker'),
                      value: effective,
                      isExpanded: true,
                      dropdownColor: context.surfaceElevated,
                      underline: const SizedBox(),
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      items: [
                        for (final e in exercises)
                          DropdownMenuItem(
                              value: e.id,
                              child: Text(
                                e.name,
                                overflow: TextOverflow.ellipsis,
                              )),
                      ],
                      onChanged: (id) {
                        if (id != null) {
                          ref
                              .read(selectedExerciseProvider.notifier)
                              .select(id);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _TrendBody(
                      exerciseId: effective,
                      weeks: weeks,
                      since: windowStart,
                      unit: unit,
                    ),
                  ],
                ),
    );
  }
}

class _TrendBody extends ConsumerWidget {
  const _TrendBody({
    required this.exerciseId,
    required this.weeks,
    required this.since,
    required this.unit,
  });

  final String? exerciseId;
  final int weeks;
  final DateTime since;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (exerciseId == null) return const SizedBox(height: 8);
    final trend = ref.watch(
        exerciseTrendProvider((exerciseId: exerciseId!, weeks: weeks)));
    return trend.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (e, st) => Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Text('Chart unavailable.',
              style: TextStyle(fontSize: 12, color: context.textTertiary)),
        ),
      ),
      data: (rows) =>
          ExerciseTrendChart(rows: rows, since: since, unit: unit),
    );
  }
}

/// Consistency card: trained-days grid sized to the selected window
/// (watches its own providers).
class ConsistencyCard extends ConsumerWidget {
  const ConsistencyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeks = ref.watch(analyticsPeriodProvider);
    final daysAsync = ref.watch(calendarDaysProvider);
    final days = daysAsync.value ?? const <DateTime>{};
    final now = DateTime.now();

    // Grid rows = the selected period; "All" stretches back to the first
    // trained day (never shorter than the familiar 12-week view).
    var rows = weeks > 0 ? weeks : 12;
    if (weeks <= 0 && days.isNotEmpty) {
      var earliest = days.first;
      for (final d in days) {
        if (d.isBefore(earliest)) earliest = d;
      }
      final derived =
          daysBetween(weekStartOf(earliest), weekStartOf(now)) ~/ 7 + 1;
      if (derived > rows) rows = derived;
    }

    return ChartCard(
      title: 'Consistency',
      subtitle: weeks > 0
          ? 'last $weeks weeks · trained days'
          : 'all history · trained days',
      child: daysAsync.isLoading && days.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          : ConsistencyCalendar(days: days, now: now, rows: rows),
    );
  }
}
