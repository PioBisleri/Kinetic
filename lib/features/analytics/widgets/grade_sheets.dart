import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/settings/settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weight_units.dart';
import '../domain/grade_engine.dart';

/// Tap a grade chip → the breakdown sheet: formula, the three weighted
/// components with their raw inputs, the freshness verdict, and the tier
/// ladder. Everything the engine already computed, spelled out.
Future<void> showGradeBreakdownSheet(
  BuildContext context, {
  required String muscleName,
  required GradeResult result,
  required double volumeKg30d,
  required double? bestE1RmKg,
  required double bodyweightKg,
  required int daysTrained30d,
  required int targetSessions,
  required double hoursSinceTrained,
  required UnitSystem unit,
}) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      builder: (_) => _GradeBreakdownSheet(
        muscleName: muscleName,
        result: result,
        volumeKg30d: volumeKg30d,
        bestE1RmKg: bestE1RmKg,
        bodyweightKg: bodyweightKg,
        daysTrained30d: daysTrained30d,
        targetSessions: targetSessions,
        hoursSinceTrained: hoursSinceTrained,
        unit: unit,
      ),
    );

/// Info button on the Muscle Grades card → how the whole thing works.
Future<void> showHowGradesWorkSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      builder: (_) => const _HowGradesWorkSheet(),
    );

/// Display weight with grouping: '34,640' / '4,409.25'.
String _weight(double kg, UnitSystem unit) {
  var v = kgToDisplay(kg, unit);
  if (unit == UnitSystem.lbs) v = (v * 2).round() / 2; // snap to 0.5 lb
  return NumberFormat.decimalPattern().format(v);
}

String _mult(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';

class _GradeBreakdownSheet extends StatelessWidget {
  const _GradeBreakdownSheet({
    required this.muscleName,
    required this.result,
    required this.volumeKg30d,
    required this.bestE1RmKg,
    required this.bodyweightKg,
    required this.daysTrained30d,
    required this.targetSessions,
    required this.hoursSinceTrained,
    required this.unit,
  });

  final String muscleName;
  final GradeResult result;
  final double volumeKg30d;
  final double? bestE1RmKg;
  final double bodyweightKg;
  final int daysTrained30d;
  final int targetSessions;
  final double hoursSinceTrained;
  final UnitSystem unit;

  // ---- raw input lines, one per component -------------------------------

  String get _volumeRaw {
    final target =
        GradeEngine.volumeWeekTarget * GradeEngine.volumeWeekTargetWeeks;
    final lbl = unitLabel(unit);
    return '${_weight(volumeKg30d, unit)} $lbl in 30 days'
        ' · target ${_weight(target, unit)} $lbl';
  }

  String get _strengthRaw {
    if (bestE1RmKg == null || bestE1RmKg! <= 0) return 'No e1RM logged yet';
    final target = GradeEngine.e1RmTargetsPerBw[result.muscleId];
    if (target == null || target <= 0) {
      return 'No bodyweight standard for this muscle — component skipped';
    }
    final lbl = unitLabel(unit);
    return 'Best e1RM ${_weight(bestE1RmKg!, unit)} $lbl'
        ' · standard ${_weight(bodyweightKg * target, unit)} $lbl'
        ' (${_mult(target)}× bodyweight)';
  }

  String get _consistencyRaw {
    final since = hoursSinceTrained.isInfinite
        ? 'never trained'
        : '${hoursSinceTrained.round()}h since last';
    return '$daysTrained30d of $targetSessions sessions in 30 days'
        ' · $since';
  }

  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final r = result;
    final w = GradeEngine.weights;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    muscleName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  r.grade,
                  style: TextStyle(
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gradeColor(r.grade),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${r.score.round()} pts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '0.40 × Volume + 0.40 × Strength + 0.20 × Consistency',
              style: TextStyle(fontSize: 12, color: context.textTertiary),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            _component(
              context,
              label: 'Volume · 40%',
              score: r.volumeScore,
              points: r.volumeScore * w.volume,
              raw: _volumeRaw,
            ),
            const Divider(height: 1),
            _component(
              context,
              label: 'Strength · 40%',
              score: r.strengthScore,
              points: r.strengthScore * w.strength,
              raw: _strengthRaw,
            ),
            const Divider(height: 1),
            _component(
              context,
              label: 'Consistency · 20%',
              score: r.consistencyScore,
              points: r.consistencyScore * w.consistency,
              raw: _consistencyRaw,
            ),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 15, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    GradeEngine.freshnessVerdict(hoursSinceTrained),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'TIER THRESHOLDS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: context.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final (letter, min)
                    in const [('S', 90), ('A', 78), ('B', 64), ('C', 48), ('D', 30), ('F', 0)])
                  _tierChip(context, letter, min),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Computed on-device over a rolling 30-day window. '
              'Nothing leaves your phone.',
              style: TextStyle(fontSize: 11, color: context.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _component(
    BuildContext context, {
    required String label,
    required double score,
    required double points,
    required String raw,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondary,
                  ),
                ),
              ),
              Text(
                '${score.round()} · ${points.round()} pts',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            raw,
            style: TextStyle(fontSize: 11, color: context.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _tierChip(BuildContext context, String letter, int min) {
    final current = letter == result.grade;
    final color = AppColors.gradeColor(letter);
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: current ? color : Colors.transparent,
            border: Border.all(color: current ? color : context.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: current ? Colors.black : color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          min == 0 ? '<30' : '≥ $min',
          style: TextStyle(fontSize: 10, color: context.textTertiary),
        ),
      ],
    );
  }
}

class _HowGradesWorkSheet extends StatelessWidget {
  const _HowGradesWorkSheet();

  @override
  Widget build(BuildContext context) {
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
              'How grades work',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            _section(
              context,
              'Formula',
              'Score = 0.40 × Volume + 0.40 × Strength + 0.20 × Consistency '
                  '— each part is scored 0–100 over the window.',
            ),
            _section(
              context,
              'Volume · 40%',
              'Hard-set volume per muscle over the last 30 days, log-scaled '
                  'against an 8,000 kg/week target. Hitting the target '
                  'earns 100.',
            ),
            _section(
              context,
              'Strength · 40%',
              "Your best e1RM for the muscle's main lift vs a bodyweight "
                  'standard (bench 1.0×, squat 1.5×, deadlift 2.0× …). '
                  'Muscles with no standard (abs) skip this part.',
            ),
            _section(
              context,
              'Consistency · 20%',
              'Sessions vs a target of 8 per 30 days, damped by freshness: '
                  'credit fades to 0 after 72h without training that muscle.',
            ),
            _section(
              context,
              'Tiers',
              'S ≥ 90 · A ≥ 78 · B ≥ 64 · C ≥ 48 · D ≥ 30 · F below 30.',
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'Everything is computed on-device from your own logs. '
              'No social features — nothing is ever shared.',
              style: TextStyle(fontSize: 11, color: context.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String label, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: context.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
