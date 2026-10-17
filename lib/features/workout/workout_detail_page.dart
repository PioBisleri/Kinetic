import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/weight_units.dart';
import '../analytics/domain/analytics_math.dart' show compactNumber;
import 'application/workout_detail_provider.dart';

/// `/workout-history/:id` — read-only viewer for a finished workout:
/// per-exercise blocks with every set row as logged (warm-ups, drops,
/// failures and all). Reached from Home's "Recent workouts" tiles; delete
/// stays on Home (long-press), this page only presents.
class WorkoutDetailPage extends ConsumerWidget {
  const WorkoutDetailPage({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(workoutDetailProvider(workoutId));

    return Scaffold(
      appBar: AppBar(title: const Text('Workout history')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Could not load the workout.',
            style: TextStyle(color: context.textSecondary),
          ),
        ),
        data: (detail) {
          if (detail == null || detail.groups.isEmpty) {
            return Center(
              child: Text(
                'This workout no longer exists.',
                style: TextStyle(color: context.textSecondary),
              ),
            );
          }
          return _Detail(
            detail: detail,
            unit: ref.watch(settingsProvider).unit,
          );
        },
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.detail, required this.unit});

  final WorkoutDetail detail;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    final w = detail.workout;
    final minutes = (w.durationSec ?? 0) ~/ 60;
    final duration =
        minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header: what/when/how long + the totals Home's tile prints.
        Text(
          detail.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          '${DateFormat('EEE, MMM d · HH:mm').format(w.startedAt)} · $duration',
          style: TextStyle(fontSize: 13, color: context.textSecondary),
        ),
        if (w.notes?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text(
            w.notes!.trim(),
            style: TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, color: context.textSecondary),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.surfaceElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: context.border),
          ),
          child: Text(
            '${detail.setCount} sets · '
            '${compactNumber(kgToDisplay(detail.volumeKg, unit))} ${unitLabel(unit)} volume',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
        ),
        const SizedBox(height: 16),
        for (final group in detail.groups) ...[
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  onTap: () => context.push('/library/${group.exerciseId}'),
                  title: Text(
                    group.exerciseName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  subtitle: Text(
                    '${group.sets.where((s) => s.isCompleted).length}/${group.sets.length} sets',
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                ),
                for (var i = 0; i < group.sets.length; i++)
                  _SetRow(
                    index: i + 1,
                    set: group.sets[i],
                    unit: unit,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.index, required this.set, required this.unit});

  final int index;
  final WorkoutSet set;
  final UnitSystem unit;

  String get _type {
    switch (set.setType) {
      case 'warmup':
        return 'W';
      case 'drop':
        return 'D';
      case 'failure':
        return 'F';
      default:
        return index.toString();
    }
  }

  bool get _isHard => const {'working', 'drop', 'failure'}.contains(set.setType);

  String _weight(UnitSystem unit) {
    final kg = set.weightKg ?? 0.0;
    final value = kgToDisplay(kg, unit);
    final shown = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$shown ${unitLabel(unit)}';
  }

  @override
  Widget build(BuildContext context) {
    final completed = set.isCompleted;
    final dimmed = !completed;

    // Cardio sets log distance/duration instead of weight × reps.
    final main = set.distanceM != null || set.durationSec != null
        ? <String>[
            if (set.distanceM != null) _distance(set.distanceM!),
            if (set.durationSec != null) '${set.durationSec} s',
          ].join(' · ')
        : '${_weight(unit)} × ${set.reps ?? 0}';

    final details = <String>[];
    if (set.rpe != null) details.add('RPE ${set.rpe!.round()}');

    return ListTile(
      dense: true,
      enabled: completed,
      leading: SizedBox(
        width: 26,
        child: Text(
          _type,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: !_isHard
                ? AppColors.heatWarm
                : completed
                    ? context.textPrimary
                    : context.textTertiary,
          ),
        ),
      ),
      title: Text(
        main,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: completed ? null : context.textTertiary,
        ),
      ),
      subtitle: details.isEmpty
          ? null
          : Text(
              details.join(' · '),
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
      trailing: completed
          ? Icon(Icons.check_circle_rounded, size: 18, color: context.accent)
          : Icon(Icons.radio_button_unchecked, size: 18, color: dimmed ? context.textTertiary : null),
    );
  }

  String _distance(double meters) {
    final km = meters / 1000;
    return km >= 1
        ? '${km.toStringAsFixed(1)} km'
        : '${meters.round()} m';
  }
}
