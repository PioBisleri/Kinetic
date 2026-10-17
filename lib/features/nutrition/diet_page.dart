import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import '../../core/widgets/app_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../health/health_providers.dart';
import '../health/live_activity_service.dart';
import '../../core/widgets/app_empty.dart';
import 'application/nutrition_providers.dart';
import 'domain/food_math.dart';
import 'food_sheets.dart';

/// The /diet route: today's macro progress, water intake, logged foods,
/// and the food library. Everything writes straight to the local DB; the
/// streams re-emit because drift watches its own tables.
class DietPage extends ConsumerWidget {
  const DietPage({super.key});

  /// Rank-and-pick a food from the library, then log one serving.
  Future<void> _openPicker(BuildContext context) => showAppSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const FoodPickerSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(todayKeyProvider);
    final settings = ref.watch(settingsProvider);
    final totals = ref.watch(macroTotalsProvider(day));
    final logsAsync = ref.watch(foodLogsProvider(day));
    final libraryAsync = ref.watch(foodLibraryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Diet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MacroCard(totals: totals, settings: settings),
          const SizedBox(height: 16),
          const _StepsCard(),
          const SizedBox(height: 16),
          const _WaterCard(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Today\'s food',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton.filledTonal(
                key: const Key('diet-log-food'),
                tooltip: 'Log food',
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => unawaited(_openPicker(context)),
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          logsAsync.when(
            loading: () => const SizedBox(
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e'),
            ),
            data: (logs) => logs.isEmpty
                ? const EmptyState(message: 'Nothing logged yet.')
                : Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < logs.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _LogTile(log: logs[i]),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'My foods',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton.filledTonal(
                key: const Key('diet-new-food'),
                tooltip: 'New food',
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => unawaited(showFoodEditorSheet(context)),
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          libraryAsync.when(
            loading: () => const SizedBox(
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e'),
            ),
            data: (foods) => foods.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No foods yet — "New food" saves one with '
                          'per-serving macros you can tap to log.',
                          style: TextStyle(color: context.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                : Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final food in foods) _LibraryTile(food: food),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ------------------------------- macros ------------------------------------

class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.totals, required this.settings});

  final MacroTotals totals;
  final SettingsState settings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TODAY',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(color: context.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  totals.kcal.round().toString(),
                  key: const Key('diet-kcal-today'),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '/ ${settings.kcalTarget} kcal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Scale(
              done: totals.kcal,
              target: settings.kcalTarget.toDouble(),
              keyTag: 'diet-kcal-scale',
            ),
            const SizedBox(height: 16),
            _MacroRow(
              label: 'Protein',
              done: totals.proteinG,
              target: settings.proteinTargetG,
            ),
            _MacroRow(
              label: 'Carbs',
              done: totals.carbsG,
              target: settings.carbsTargetG,
            ),
            _MacroRow(
              label: 'Fat',
              done: totals.fatG,
              target: settings.fatTargetG,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.done,
    required this.target,
  });

  final String label;
  final double done;
  final int target;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
          ),
          Expanded(child: _Scale(done: done, target: target.toDouble())),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text.rich(
              TextSpan(
                text: done.round().toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                children: [
                  if (target > 0)
                    TextSpan(
                      text: ' / $target g',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
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

/// Thin progress bar on the accent color — value clamped to 0..1, so an
/// over-target day reads "full" rather than overflowing.
class _Scale extends StatelessWidget {
  const _Scale({required this.done, required this.target, this.keyTag});

  final double done;
  final double target;
  final String? keyTag;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: LinearProgressIndicator(
          key: keyTag == null ? null : Key(keyTag!),
          value: progress(done, target),
          minHeight: 6,
          backgroundColor: context.textTertiary.withValues(alpha: 0.18),
          color: context.accent,
        ),
      ),
    );
  }
}

// ------------------------------- steps -------------------------------------

/// Steps card (Round 9): today's phone step count vs. the target. Read-only
/// — steps come from the step sensor via the pedometer stream and (while
/// enabled) the live-notification foreground service, never manual entry.
class _StepsCard extends ConsumerWidget {
  const _StepsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(todayKeyProvider);
    final metric = ref.watch(dayMetricProvider(day)).value;
    final settings = ref.watch(settingsProvider);
    final steps = metric?.steps ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'STEPS',
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(color: context.textSecondary),
                ),
                const Spacer(),
                Text.rich(
                  TextSpan(
                    text: '$steps',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    children: [
                      TextSpan(
                        text: ' / ${settings.stepsTarget} steps',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: LinearProgressIndicator(
                  key: const Key('diet-steps-scale'),
                  value: progress(
                    steps.toDouble(),
                    settings.stepsTarget.toDouble(),
                  ),
                  minHeight: 6,
                  color: context.accent,
                  backgroundColor:
                      context.textTertiary.withValues(alpha: 0.18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------- water -------------------------------------

/// Quick-log card. Buttons write straight through [addWaterMl]; the undo
/// snackbar subtracts exactly what was added, so double-undo can't run
/// water negative.
class _WaterCard extends ConsumerWidget {
  const _WaterCard();

  static int _pct(int ml, int target) {
    if (ml <= 0) return 0;
    if (target <= 0) return 100;
    return ((ml / target) * 100).round().clamp(0, 999);
  }

  void _tap(BuildContext context, WidgetRef ref, int ml) {
    final day = ref.read(todayKeyProvider);
    final db = ref.read(databaseProvider);
    // Capture the messenger before the async gap (use_build_context…).
    final messenger = ScaffoldMessenger.maybeOf(context);
    final live = ref.read(liveActivityControllerProvider);
    unawaited(addWaterMl(db, day, ml).then((_) {
      live.refresh();
      if (messenger == null) return;
      messenger.showSnackBar(SnackBar(
        content: Text('+$ml ml water'),
        duration: const Duration(seconds: 4),
        persist: false,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              unawaited(addWaterMl(db, ref.read(todayKeyProvider), -ml)),
        ),
      ));
    }));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(todayKeyProvider);
    final metric = ref.watch(dayMetricProvider(day)).value;
    final settings = ref.watch(settingsProvider);
    final waterMl = metric?.waterMl ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'WATER',
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(color: context.textSecondary),
                ),
                const Spacer(),
                Text.rich(
                  TextSpan(
                    text: '$waterMl',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    children: [
                      TextSpan(
                        text: ' / ${settings.waterTargetMl} ml',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.water_drop,
                    size: 14,
                    color: context.accent.withValues(
                      alpha: waterMl == 0 ? 0.5 : 1.0,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: LinearProgressIndicator(
                        key: const Key('diet-water-scale'),
                        value: progress(
                          waterMl.toDouble(),
                          settings.waterTargetMl.toDouble(),
                        ),
                        minHeight: 8,
                        color: context.accent,
                        backgroundColor:
                            context.textTertiary.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '${_pct(waterMl, settings.waterTargetMl)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.textTertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // One segmented control instead of three heavy buttons —
            // Single SegmentedButton with quick-add amounts.
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                key: const Key('diet-water-segments'),
                showSelectedIcon: false,
                emptySelectionAllowed: true,
                selected: const <int>{},
                onSelectionChanged: (sel) {
                  if (sel.isNotEmpty) _tap(context, ref, sel.first);
                },
                segments: const [
                  ButtonSegment(value: 100, label: Text('+100')),
                  ButtonSegment(value: 250, label: Text('+250')),
                  ButtonSegment(value: 500, label: Text('+500')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------- tiles -------------------------------------

class _LogTile extends ConsumerWidget {
  const _LogTile({required this.log});

  final FoodLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = DateFormat('HH:mm').format(log.loggedAt);
    final foodRepo = ref.read(foodRepositoryProvider);
    return ListTile(
      dense: true,
      title: Text(
        log.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
      ),
      subtitle: Text(
        '${_servings(log.servings)} · $time',
        style: TextStyle(fontSize: 12.5, color: context.textSecondary),
      ),
      leading: IconButton(
        key: Key('diet-log-delete-${log.id}'),
        icon: Icon(Icons.close_rounded,
            size: 20, color: context.textTertiary),
        onPressed: () {
          foodRepo.deleteLog(log.id);
          final messenger = ScaffoldMessenger.maybeOf(context);
          if (messenger == null) return;
          messenger.showSnackBar(SnackBar(
            content: Text('Removed ${log.name}'),
            duration: const Duration(seconds: 4),
            persist: false,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => foodRepo.restoreLog(log.id),
            ),
          ));
        },
      ),
      trailing: Text(
        '${log.kcal.round()} kcal',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }

  static String _servings(double servings) {
    final whole = servings.roundToDouble() == servings;
    final n = whole ? servings.round().toString() : servings.toStringAsFixed(1);
    final plural = servings == 1 ? '' : 's';
    return '$n serving$plural';
  }
}

class _LibraryTile extends ConsumerWidget {
  const _LibraryTile({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servingLabel = '${_fmt(food.servingSize)} ${food.servingUnit}';
    final foodRepo = ref.read(foodRepositoryProvider);
    return ListTile(
      dense: true,
      title: Text(
        food.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
      ),
      subtitle: Text(
        'per $servingLabel · ${food.kcal.round()} kcal · '
        'P ${food.proteinG.round()} / C ${food.carbsG.round()} / '
        'F ${food.fatG.round()} g',
        style: TextStyle(fontSize: 12.5, color: context.textSecondary),
      ),
      trailing: IconButton(
        key: Key('diet-food-edit-${food.id}'),
        icon: const Icon(Icons.edit_outlined, size: 20),
        onPressed: () =>
            unawaited(showFoodEditorSheet(context, food: food)),
      ),
      selected: false,
      onTap: () {
        // One tap = log one serving straight through, same contract as
        // the picker rows.
        final day = ref.read(todayKeyProvider);
        unawaited(foodRepo.logFood(dayKey: day, food: food, servings: 1));
        ref.read(liveActivityControllerProvider).refresh();
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;
        messenger.showSnackBar(SnackBar(
          content: Text('Logged ${food.name} · 1 serving'),
          duration: const Duration(seconds: 3),
        ));
      },
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
}
