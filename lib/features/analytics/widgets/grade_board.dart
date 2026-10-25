import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/ledger/ledger.dart';
import '../../../core/settings/settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../application/analytics_providers.dart';
import '../domain/grade_engine.dart';
import 'charts.dart';
import 'grade_sheets.dart';

typedef _GradeCell = ({
  String muscleId,
  String name,
  GradeResult result,
  double volumeKg,
  double? bestE1Rm,
  int daysTrained,
  double hours,
});

List<_GradeCell> _gradeCells(WidgetRef ref) {
  final muscles = ref.watch(musclesProvider).value;
  final window = ref.watch(muscleWindowProvider).value;
  final bodyweight = ref.watch(profileProvider).value?.bodyweightKg ?? 0;
  if (muscles == null || window == null) return const [];

  final now = DateTime.now();
  final cells = <_GradeCell>[];
  for (final m in muscles) {
    if (m.id == 'cardio') continue;
    final w = window[m.id];
    final result = GradeEngine.grade(
      muscleId: m.id,
      volumeKg30d: w?.volumeKg ?? 0,
      bestE1RmKg: (w == null || w.bestE1Rm <= 0) ? null : w.bestE1Rm,
      bodyweightKg: bodyweight,
      daysTrained30d: w?.days.length ?? 0,
      targetSessions: GradeEngine.defaultTargetSessions,
      hoursSinceTrained: w?.hoursSinceTrained(now) ?? double.infinity,
    );
    cells.add((
      muscleId: m.id,
      name: m.name,
      result: result,
      volumeKg: w?.volumeKg ?? 0,
      bestE1Rm: (w == null || w.bestE1Rm <= 0) ? null : w.bestE1Rm,
      daysTrained: w?.days.length ?? 0,
      hours: w?.hoursSinceTrained(now) ?? double.infinity,
    ));
  }
  return cells;
}

/// Compact grade ledger — six muscles needing attention first, every
/// grade one tap away in the all-grades sheet.
class GradeBoardCard extends ConsumerWidget {
  const GradeBoardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscles = ref.watch(musclesProvider).value;
    final window = ref.watch(muscleWindowProvider).value;
    final bodyweight = ref.watch(profileProvider).value?.bodyweightKg ?? 0;

    if (muscles == null || window == null) {
      return const ChartCard(
        title: 'Muscle Grades',
        subtitle: '30-day rolling · volume + strength + consistency',
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

    final cells = _gradeCells(ref)
      ..sort((a, b) {
        final byScore = a.result.score.compareTo(b.result.score);
        return byScore != 0 ? byScore : a.name.compareTo(b.name);
      });
    final preview = cells.take(6).toList();

    return ChartCard(
      title: 'Muscle Grades',
      subtitle: '30-day rolling · volume + strength + consistency',
      onInfo: () => showHowGradesWorkSheet(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in preview.indexed) ...[
            if (i > 0) Divider(height: 1, color: context.border),
            _GradeRow(
              cell: c,
              onTap: () => _openBreakdown(context, ref, c, bodyweight),
            ),
          ],
          Divider(height: 1, color: context.border),
          InkWell(
            key: const Key('grades-all'),
            onTap: () => showAppSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const _AllGradesSheet(),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Text(
                    'SEE ALL ${cells.length} GRADES',
                    style: AppType.meta.copyWith(color: context.accent),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: context.accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _openBreakdown(
  BuildContext context,
  WidgetRef ref,
  _GradeCell c,
  double bodyweight,
) {
  showGradeBreakdownSheet(
    context,
    muscleName: c.name,
    result: c.result,
    volumeKg30d: c.volumeKg,
    bestE1RmKg: c.bestE1Rm,
    bodyweightKg: bodyweight,
    daysTrained30d: c.daysTrained,
    targetSessions: GradeEngine.defaultTargetSessions,
    hoursSinceTrained: c.hours,
    unit: ref.read(settingsProvider).unit,
  );
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.cell, required this.onTap});

  final _GradeCell cell;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('grade-${cell.muscleId}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                cell.result.grade,
                style: TextStyle(
                  fontFamily: AppType.h1.fontFamily,
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gradeColor(cell.result.grade),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                cell.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ),
            Text(
              '${cell.result.score.round()} pts',
              style: AppType.dataSm.copyWith(color: context.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllGradesSheet extends ConsumerWidget {
  const _AllGradesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cells = _gradeCells(ref)
      ..sort((a, b) {
        final byScore = a.result.score.compareTo(b.result.score);
        return byScore != 0 ? byScore : a.name.compareTo(b.name);
      });
    final bodyweight = ref.watch(profileProvider).value?.bodyweightKg ?? 0;

    return FractionallySizedBox(
      key: const Key('grades-sheet'),
      heightFactor: 0.9,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'All grades',
                      style: AppType.h1.copyWith(color: context.textPrimary),
                    ),
                  ),
                  IconButton(
                    key: const Key('grades-close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            Rule(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, c) in cells.indexed) ...[
                      if (i > 0) Divider(height: 1, color: context.border),
                      _GradeRow(
                        cell: c,
                        onTap: () =>
                            _openBreakdown(context, ref, c, bodyweight),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
