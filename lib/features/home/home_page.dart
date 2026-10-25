import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/ledger/ledger.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/weight_units.dart';
import '../../core/widgets/app_dialog.dart';
import '../analytics/application/analytics_providers.dart';
import '../analytics/domain/analytics_math.dart';
import '../health/health_providers.dart';
import '../nutrition/application/nutrition_providers.dart';
import '../routines/application/routine_providers.dart';
import '../workout/application/workout_session_notifier.dart';
import 'application/home_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    await ref.read(workoutSessionProvider.notifier).startWorkout();
    if (context.mounted) context.push('/workout');
  }

  Future<void> _startRoutine(
      BuildContext context, WidgetRef ref, String routineId) async {
    final session = ref.read(workoutSessionProvider).value;
    if (session != null) {
      showSnack(context, 'Finish your current workout first.');
      return;
    }
    await ref
        .read(workoutSessionProvider.notifier)
        .startWorkout(routineId: routineId);
    if (context.mounted) context.push('/workout');
  }

  void _openRoutinePicker(BuildContext context, WidgetRef ref) {
    showAppSheet<void>(
      context: context,
      builder: (_) => Consumer(
        builder: (sheetContext, ref, _) {
          final cards = ref.watch(routinesProvider);
          final routines = cards.value ?? const <RoutineCard>[];
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    'START FROM ROUTINE',
                    style: AppType.meta.copyWith(
                      color: sheetContext.textTertiary,
                    ),
                  ),
                ),
                for (final card in routines)
                  LedgerRow(
                    key: Key('home-routine-${card.routine.id}'),
                    label: card.routine.name,
                    value: '${card.exerciseCount} ex',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _startRoutine(context, ref, card.routine.id);
                    },
                  ),
                if (routines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Text(
                      'No routines yet — create one from the Routines tab.',
                      style: AppType.bodySm.copyWith(
                        color: sheetContext.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(workoutSessionProvider);
    final unit = ref.watch(settingsProvider).unit;
    final now = DateTime.now();

    return Scaffold(
      appBar: TailBar(
        title: 'Kinetic',
        meta: '${DateFormat('EEE d MMM').format(now)} · W${_weekOfYear(now)}',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.x5,
          AppSpace.x1,
          AppSpace.x5,
          AppSpace.x8,
        ),
        children: [
          sessionAsync.when(
            loading: () => const LedgerPanel(
              child: SizedBox(
                height: 120,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
            error: (e, _) => LedgerPanel(child: Text('Error: $e')),
            data: (session) => session == null
                ? _StartBlock(
                    onStart: () => _start(context, ref),
                    onStartRoutine: () => _openRoutinePicker(context, ref),
                  )
                : _ActiveBlock(
                    session: session,
                    onResume: () => context.push('/workout'),
                  ),
          ),
          const SizedBox(height: AppSpace.x6),
          const _TodaySection(),
          const SizedBox(height: AppSpace.x6),
          _HomeStats(unit: unit),
          const SizedBox(height: AppSpace.x6),
          const SectionHead(
            index: '03',
            title: 'Recent workouts',
            meta: 'TAP TO REVIEW',
          ),
          const SizedBox(height: AppSpace.x3),
          const _RecentWorkouts(),
        ],
      ),
    );
  }
}

int _weekOfYear(DateTime date) {
  final first = DateTime(date.year, 1, 1);
  return ((date.difference(first).inDays + first.weekday) / 7).ceil();
}

String _two(int value) => value.toString().padLeft(2, '0');

class _StartBlock extends StatelessWidget {
  const _StartBlock({
    required this.onStart,
    required this.onStartRoutine,
  });

  final VoidCallback onStart;
  final VoidCallback onStartRoutine;

  @override
  Widget build(BuildContext context) {
    return LedgerPanel(
      accentTop: true,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, color: context.accent),
              const SizedBox(width: 8),
              Text(
                'READY',
                style: AppType.meta.copyWith(color: context.accent),
              ),
              const Spacer(),
              Text(
                'NO ACTIVE SESSION',
                style: AppType.metaSm.copyWith(color: context.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Start a session',
            style: AppType.h1.copyWith(color: context.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            "Empty session or a saved routine. Log it or it didn't happen.",
            style: AppType.bodySm.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: 18),
          PushKey(
            label: 'Start Workout',
            onPressed: onStart,
            icon: LedgerGlyph(
              LedgerGlyphType.play,
              size: 15,
              strokeWidth: 2,
              color: onAccent(context.accent),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onStartRoutine,
              style: TextButton.styleFrom(
                foregroundColor: context.textSecondary,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                textStyle: AppType.meta.copyWith(letterSpacing: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('START FROM ROUTINE'),
                  const SizedBox(width: 6),
                  LedgerGlyph(
                    LedgerGlyphType.chevronRight,
                    size: 12,
                    color: context.textSecondary,
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

class _ActiveBlock extends StatelessWidget {
  const _ActiveBlock({required this.session, required this.onResume});

  final WorkoutSession session;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return LedgerPanel(
      accentTop: true,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, color: context.signal),
              const SizedBox(width: 8),
              Text(
                'WORKOUT IN PROGRESS',
                style: AppType.meta.copyWith(color: context.signal),
              ),
              const Spacer(),
              Text(
                formatElapsed(session.elapsed),
                style: AppType.dataLg.copyWith(color: context.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MetaStat(
                value: _two(session.exercises.length),
                label: 'EXERCISES',
              ),
              const SizedBox(width: 18),
              _MetaStat(
                value: _two(session.completedSetCount),
                label: 'SETS',
              ),
              const SizedBox(width: 18),
              _MetaStat(
                value: session.volumeKg.toStringAsFixed(0),
                label: 'KG VOLUME',
              ),
            ],
          ),
          const SizedBox(height: 16),
          PushKey(
            label: 'Resume Workout',
            onPressed: onResume,
            icon: LedgerGlyph(
              LedgerGlyphType.timer,
              size: 16,
              strokeWidth: 1.8,
              color: onAccent(context.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaStat extends StatelessWidget {
  const _MetaStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: AppType.dataLg.copyWith(color: context.textPrimary),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppType.metaSm.copyWith(color: context.textTertiary),
        ),
      ],
    );
  }
}

/// One-tap glance at today's hydration, steps and calories — each row
/// jumps into the /diet page (single surface for all three).
class _TodaySection extends ConsumerWidget {
  const _TodaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(todayKeyProvider);
    final metric = ref.watch(dayMetricProvider(day)).value;
    final totals = ref.watch(macroTotalsProvider(day));
    final settings = ref.watch(settingsProvider);

    final kcalLeft =
        (settings.kcalTarget - totals.kcal.round()).clamp(0, 99999);
    final steps = metric?.steps;
    final water = metric?.waterMl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(
          index: '01',
          title: 'Today',
          meta: DateFormat('EEE').format(DateTime.now()).toUpperCase(),
        ),
        const SizedBox(height: AppSpace.x3),
        LedgerPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              LedgerRow(
                key: const Key('home-today-water'),
                label: 'Water',
                value: water == null ? '–' : '$water',
                unit: 'ml',
                onTap: () => context.push('/diet'),
              ),
              LedgerRow(
                key: const Key('home-today-steps'),
                label: 'Steps',
                value: steps == null
                    ? '–'
                    : compactNumber(steps.toDouble()).toString(),
                onTap: () => context.push('/diet'),
              ),
              LedgerRow(
                key: const Key('home-today-kcal'),
                label: 'Kcal left',
                value: '$kcalLeft',
                unit: 'kcal',
                valueColor: context.accent,
                divider: false,
                onTap: () => context.push('/diet'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The three headline stats, computed from real history: workouts finished
/// this week (Mon-start), total working volume this week, and the weekly
/// streak. Mirrors Analytics' `StatsRow` numbers exactly (same providers).
class _HomeStats extends ConsumerWidget {
  const _HomeStats({required this.unit});

  final UnitSystem unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(workoutStatsProvider(1)).value;
    final daily = ref.watch(dailyVolumeProvider(1)).value;

    final header = SectionHead(
      index: '02',
      title: 'This week',
      meta: 'MON — SUN',
    );

    if (stats == null || daily == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: AppSpace.x3),
          LedgerPanel(
            grid: true,
            padding: EdgeInsets.zero,
            child: StatBlocks(
              children: const [
                Metric(label: 'Sessions', value: '–'),
                Metric(label: 'Volume', value: '–'),
                Metric(label: 'Streak', value: '–', unit: 'wk'),
              ],
            ),
          ),
        ],
      );
    }

    final volumeKg = daily.fold(0.0, (a, r) => a + r.totalVolume);
    final streak = stats.streak;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: AppSpace.x3),
        LedgerPanel(
          grid: true,
          padding: EdgeInsets.zero,
          child: StatBlocks(
            children: [
              Metric(label: 'Sessions', value: _two(stats.count)),
              Metric(
                label: 'Volume',
                value: compactNumber(kgToDisplay(volumeKg, unit)),
                unit: unitLabel(unit),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Metric(label: 'Streak', value: '$streak', unit: 'wk'),
                  if (streak > 1) ...[
                    const SizedBox(height: 8),
                    Tally(
                      count: streak.clamp(0, 25),
                      height: 10,
                      color: context.signal,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Finished workouts, newest first. Long-press a row to delete it (with
/// confirmation); analytics rollups recompute so every chart agrees.
class _RecentWorkouts extends ConsumerWidget {
  const _RecentWorkouts();

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, RecentWorkout row) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete workout?',
      message: '${row.title} · '
          '${DateFormat('EEE, MMM d').format(row.workout.startedAt)}\n\n'
          'This removes the workout and its sets from your history. '
          'Charts and totals recompute immediately.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (confirmed != true || !context.mounted) return;
    await deleteCompletedWorkout(ref.read(databaseProvider), row.workout.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentWorkoutsProvider);
    final unit = ref.watch(settingsProvider).unit;

    return recent.when(
      loading: () => const LedgerPanel(
        child: SizedBox(
          height: 72,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (e, _) => LedgerPanel(child: Text('Error: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return LedgerPanel(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nothing logged yet.',
                  style: AppType.h2.copyWith(color: context.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'The bar is still on the floor. Start a session and it '
                  'lands here.',
                  style: AppType.bodySm.copyWith(color: context.textSecondary),
                ),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LedgerPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++)
                    _RecentRow(
                      row: rows[i],
                      unit: unit,
                      divider: i < rows.length - 1,
                      onDelete: () => _confirmDelete(context, ref, rows[i]),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.x3),
            Text(
              'TAP TO REVIEW · LONG-PRESS TO DELETE',
              style: AppType.metaSm.copyWith(color: context.textTertiary),
            ),
          ],
        );
      },
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.row,
    required this.unit,
    required this.divider,
    required this.onDelete,
  });

  final RecentWorkout row;
  final UnitSystem unit;
  final bool divider;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final w = row.workout;
    final minutes = (w.durationSec ?? 0) ~/ 60;
    final duration =
        minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';

    return LedgerRow(
      key: Key('home-recent-${w.id}'),
      label: row.title,
      sub: '${DateFormat('EEE d MMM').format(w.startedAt).toUpperCase()} · '
          '$duration · ${row.setCount} SETS',
      value: compactNumber(kgToDisplay(w.totalVolume, unit)),
      unit: unitLabel(unit),
      divider: divider,
      onTap: () => context.push('/workout-history/${w.id}'),
      onLongPress: onDelete,
    );
  }
}
