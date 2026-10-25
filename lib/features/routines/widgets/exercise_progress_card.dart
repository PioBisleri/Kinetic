import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/ledger/ledger.dart';
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
    .family<List<ProgressPoint>, String>((ref, id) {
      final db = ref.watch(databaseProvider);
      final q = db.exerciseHistory.select()
        ..where((h) => h.exerciseId.equals(id))
        ..orderBy([(h) => OrderingTerm.asc(h.date)]);
      return q.watch().map(
        (rows) => [
          for (final r in rows)
            ProgressPoint(
              date: r.date,
              e1rmKg: r.bestE1Rm,
              topWeightKg: r.topWeight,
              topReps: r.topReps,
              volumeKg: r.totalVolume,
            ),
        ],
      );
    });

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
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
    final progress = points == null ? null : ExerciseProgress.compute(points);

    if (progress == null) {
      // First session (or still loading) — invite rather than show blanks.
      return ChartCard(
        index: '02',
        title: 'Progress',
        subtitle: 'all-time records · trend',
        child: Text(
          pointsAsync.isLoading
              ? 'Loading progress…'
              : 'Log a session to see your progress.',
          style: AppType.bodySm.copyWith(color: context.textTertiary),
        ),
      );
    }

    final weeks = ref.watch(analyticsPeriodProvider);
    final trendRows =
        ref
            .watch(
              exerciseTrendProvider((
                exerciseId: widget.exerciseId,
                weeks: weeks,
              )),
            )
            .value ??
        const [];

    return ChartCard(
      index: '02',
      title: 'Progress',
      subtitle: 'all-time records · trend',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: PeriodChips(compact: true),
          ),
          const SizedBox(height: AppSpace.x3),
          _RecordsRow(progress: progress, unit: unit),
          const SizedBox(height: AppSpace.x2),
          const Rule(),
          const SizedBox(height: AppSpace.x3),
          Row(
            children: [
              Expanded(
                child: _SeriesChip(
                  key: const Key('series-e1rm'),
                  label: 'e1RM',
                  selected: _series == ExerciseSeries.e1rm,
                  onTap: () => setState(() => _series = ExerciseSeries.e1rm),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _SeriesChip(
                  key: const Key('series-volume'),
                  label: 'Volume',
                  selected: _series == ExerciseSeries.volume,
                  onTap: () => setState(() => _series = ExerciseSeries.volume),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.x2),
          ExerciseTrendChart(
            key: const Key('progress-chart'),
            rows: trendRows,
            // "All" anchors the axis at this exercise's first logged day.
            since: chartStart(weeks, DateTime.now(), [
              for (final r in trendRows) r.date,
            ]),
            unit: unit,
            series: _series,
          ),
          const SizedBox(height: AppSpace.x3),
          _LastSessionBlock(progress: progress, unit: unit),
        ],
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
    final color = selected ? context.accent : context.textSecondary;
    return Material(
      color: selected
          ? context.accent.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.data),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.data),
        onTap: onTap,
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.data),
            border: Border.all(
              color: selected
                  ? context.accent.withValues(alpha: 0.55)
                  : context.border,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: AppType.meta.copyWith(color: color, letterSpacing: 1.2),
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
    return StatBlocks(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.x2),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.dataLg.copyWith(color: context.signal),
        ),
        const SizedBox(height: 3),
        Text(
          '$label · $date',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.metaSm.copyWith(color: context.textTertiary),
        ),
      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Rule(),
        Padding(
          padding: const EdgeInsets.only(top: 11, bottom: 6),
          child: Row(
            children: [
              Text(
                'Last session',
                style: AppType.bodySm.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _fmtDate(newest.date),
                style: AppType.metaSm.copyWith(color: context.textTertiary),
              ),
            ],
          ),
        ),
        Text(
          newest.topWeightKg > 0
              ? '${formatWeight(newest.topWeightKg, unit)} $label'
                    ' × ${newest.topReps}'
              : '—',
          style: AppType.dataLg.copyWith(color: context.textPrimary),
        ),
        const SizedBox(height: AppSpace.x2),
        if (cmp == null)
          Text(
            'First session logged — comparisons appear from the next one.',
            style: AppType.bodySm.copyWith(color: context.textTertiary),
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
              const SizedBox(width: 6),
              _DeltaChip(
                key: const Key('delta-volume'),
                label: 'Volume',
                deltaKg: cmp.volumeDeltaKg,
                unit: unit,
              ),
              const Spacer(),
              Text(
                'vs previous',
                style: AppType.metaSm.copyWith(color: context.textTertiary),
              ),
            ],
          ),
      ],
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
    final sign = up
        ? '+'
        : down
        ? '-'
        : '±';
    final amount = deltaKg == 0 ? '0' : formatWeight(deltaKg.abs(), unit);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(AppRadius.data),
      ),
      child: Text(
        '$label $sign$amount ${unitLabel(unit)}',
        style: AppType.metaSm.copyWith(color: color, letterSpacing: 0.3),
      ),
    );
  }
}
