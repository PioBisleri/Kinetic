import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/settings/settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weight_units.dart';
import '../../analytics/application/analytics_providers.dart';
import '../../analytics/domain/analytics_math.dart';
import '../../analytics/widgets/charts.dart';
import '../domain/exercise_progress.dart';

/// All-time day-level history for one exercise — records are never
/// window-scoped, so this reads every `ExerciseHistory` row.
final exercisePointsProvider = StreamProvider.autoDispose
    .family<List<ProgressPoint>, String>(
  (ref, id) {
    final db = ref.watch(databaseProvider);
    final q = db.exerciseHistory.select()
      ..where((h) => h.exerciseId.equals(id))
      ..orderBy([(h) => OrderingTerm.asc(h.date)]);
    return q.watch().map((rows) => [
          for (final r in rows)
            ProgressPoint(
              date: r.date,
              e1rmKg: r.bestE1Rm,
              topWeightKg: r.topWeight,
              topReps: r.topReps,
              volumeKg: r.totalVolume,
            ),
        ]);
  },
);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// The exercise's Progress section: all-time records, a trend chart
/// (e1RM or daily volume over the shared 4W/12W/6M window), and the
/// last-vs-previous session comparison.
class ExerciseProgressCard extends ConsumerStatefulWidget {
  const ExerciseProgressCard({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  ConsumerState<ExerciseProgressCard> createState() =>
      _ExerciseProgressCardState();
}

class _ExerciseProgressCardState extends ConsumerState<ExerciseProgressCard> {
  ExerciseSeries _series = ExerciseSeries.e1rm;

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(settingsProvider).unit;
    final pointsAsync = ref.watch(exercisePointsProvider(widget.exerciseId));
    final points = pointsAsync.value;
    final progress = points == null
        ? null
        : ExerciseProgress.compute(points);

    if (progress == null) {
      // First session (or still loading) — invite rather than show blanks.
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            pointsAsync.isLoading
                ? 'Loading progress…'
                : 'Log a session to see your progress.',
            style: TextStyle(fontSize: 13, color: context.textTertiary),
          ),
        ),
      );
    }

    final weeks = ref.watch(analyticsPeriodProvider);
    final trendRows = ref
            .watch(exerciseTrendProvider(
                (exerciseId: widget.exerciseId, weeks: weeks)))
            .value ??
        const [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Progress',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const PeriodChips(),
              ],
            ),
            const SizedBox(height: 14),
            _RecordsRow(progress: progress, unit: unit),
            const SizedBox(height: 16),
            Row(
              children: [
                _SeriesChip(
                  key: const Key('series-e1rm'),
                  label: 'e1RM',
                  selected: _series == ExerciseSeries.e1rm,
                  onTap: () =>
                      setState(() => _series = ExerciseSeries.e1rm),
                ),
                const SizedBox(width: 8),
                _SeriesChip(
                  key: const Key('series-volume'),
                  label: 'Volume',
                  selected: _series == ExerciseSeries.volume,
                  onTap: () =>
                      setState(() => _series = ExerciseSeries.volume),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExerciseTrendChart(
              key: const Key('progress-chart'),
              rows: trendRows,
              // "All" anchors the axis at this exercise's first logged day.
              since: chartStart(
                weeks,
                DateTime.now(),
                [for (final r in trendRows) r.date],
              ),
              unit: unit,
              series: _series,
            ),
            const SizedBox(height: 8),
            _LastSessionBlock(progress: progress, unit: unit),
          ],
        ),
      ),
    );
  }
}

class _SeriesChip extends StatelessWidget {
  const _SeriesChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.16)
              : context.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.6)
                : context.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.accent : context.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Three record tiles: best e1RM, heaviest set, biggest day.
class _RecordsRow extends StatelessWidget {
  const _RecordsRow({required this.progress, required this.unit});

  final ExerciseProgress progress;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    final set = progress.bestSet.value;
    return Row(
      children: [
        _RecordTile(
          key: const Key('record-e1rm'),
          value: progress.bestE1rm.value > 0
              ? '${formatWeight(progress.bestE1rm.value, unit)} '
                  '${unitLabel(unit)}'
              : '—',
          label: 'Best e1RM',
          date: _fmtDate(progress.bestE1rm.date),
        ),
        _RecordTile(
          key: const Key('record-set'),
          value: set.weightKg > 0
              ? '${formatWeight(set.weightKg, unit)} × ${set.reps}'
              : '—',
          label: 'Heaviest set',
          date: _fmtDate(progress.bestSet.date),
        ),
        _RecordTile(
          key: const Key('record-volume'),
          value: progress.bestVolumeDay.value > 0
              ? '${compactNumber(kgToDisplay(progress.bestVolumeDay.value, unit))} '
                  '${unitLabel(unit)}'
              : '—',
          label: 'Volume record',
          date: _fmtDate(progress.bestVolumeDay.date),
        ),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    super.key,
    required this.value,
    required this.label,
    required this.date,
  });

  final String value;
  final String label;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$label · $date',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: context.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Newest session vs the one before it, with signed e1RM/volume deltas.
class _LastSessionBlock extends StatelessWidget {
  const _LastSessionBlock({required this.progress, required this.unit});

  final ExerciseProgress progress;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    final newest = progress.newest;
    final cmp = progress.comparison;
    final label = unitLabel(unit);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Last session',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                _fmtDate(newest.date),
                style: TextStyle(fontSize: 12, color: context.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            newest.topWeightKg > 0
                ? '${formatWeight(newest.topWeightKg, unit)} $label'
                    ' × ${newest.topReps}'
                : '—',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (cmp == null)
            Text(
              'First session logged — comparisons appear from the next one.',
              style:
                  TextStyle(fontSize: 12, color: context.textTertiary),
            )
          else
            Row(
              children: [
                _DeltaChip(
                  key: const Key('delta-e1rm'),
                  label: 'e1RM',
                  deltaKg: cmp.e1rmDeltaKg,
                  unit: unit,
                ),
                const SizedBox(width: 8),
                _DeltaChip(
                  key: const Key('delta-volume'),
                  label: 'Volume',
                  deltaKg: cmp.volumeDeltaKg,
                  unit: unit,
                ),
                const Spacer(),
                Text(
                  'vs previous',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textTertiary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({
    super.key,
    required this.label,
    required this.deltaKg,
    required this.unit,
  });

  final String label;
  final double deltaKg;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    final up = deltaKg > 0.001;
    final down = deltaKg < -0.001;
    final color = up
        ? AppColors.gradeA
        : down
            ? AppColors.heatHot
            : context.textTertiary;
    final sign = up ? '+' : down ? '-' : '±';
    final amount = deltaKg == 0
        ? '0'
        : formatWeight(deltaKg.abs(), unit);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $sign$amount ${unitLabel(unit)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
