import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../../core/widgets/app_dialog.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/settings/settings.dart';
import '../../core/ledger/ledger.dart';
import '../../core/theme/app_theme.dart';
import '../health/health_providers.dart';
import '../health/live_activity_service.dart';
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
      appBar: const TailBar(
        title: 'Diet',
        meta: 'Macros · water · movement',
        showMenu: false,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.x5,
            AppSpace.x2,
            AppSpace.x5,
            AppSpace.x8,
          ),
          children: [
            const SectionHead(index: '01', title: 'Intake', meta: 'macros'),
            const SizedBox(height: AppSpace.x3),
            _MacroCard(totals: totals, settings: settings),
            const SizedBox(height: AppSpace.x6),
            const SectionHead(
              index: '02',
              title: 'Movement',
              meta: 'sensor only',
            ),
            const SizedBox(height: AppSpace.x3),
            const _StepsCard(),
            const SizedBox(height: AppSpace.x6),
            const SectionHead(index: '03', title: 'Water', meta: 'quick log'),
            const SizedBox(height: AppSpace.x3),
            const _WaterCard(),
            const SizedBox(height: AppSpace.x6),
            _FeedHeader(
              index: '04',
              title: "Today's food",
              meta: 'logged',
              action: _AddButton(
                key: const Key('diet-log-food'),
                tooltip: 'Log food',
                onPressed: () => unawaited(_openPicker(context)),
              ),
            ),
            const SizedBox(height: AppSpace.x3),
            logsAsync.when(
              loading: () => const _LoadingPanel(),
              error: (e, _) => _MessagePanel(message: 'Error: $e'),
              data: (logs) => logs.isEmpty
                  ? const _MessagePanel(message: 'Nothing logged yet.')
                  : LedgerPanel(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < logs.length; i++) ...[
                            if (i > 0) Rule(),
                            _LogTile(log: logs[i]),
                          ],
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: AppSpace.x6),
            _FeedHeader(
              index: '05',
              title: 'My foods',
              meta: 'library',
              action: _AddButton(
                key: const Key('diet-new-food'),
                tooltip: 'New food',
                onPressed: () => unawaited(showFoodEditorSheet(context)),
              ),
            ),
            const SizedBox(height: AppSpace.x3),
            libraryAsync.when(
              loading: () => const _LoadingPanel(),
              error: (e, _) => _MessagePanel(message: 'Error: $e'),
              data: (foods) => foods.isEmpty
                  ? const _MessagePanel(
                      message:
                          'No foods yet — "New food" saves one with '
                          'per-serving macros you can tap to log.',
                    )
                  : LedgerPanel(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final food in foods) _LibraryTile(food: food),
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

// ------------------------------- macros ------------------------------------

class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.totals, required this.settings});

  final MacroTotals totals;
  final SettingsState settings;

  @override
  Widget build(BuildContext context) {
    return LedgerPanel(
      grid: true,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'KCAL TODAY',
                  style: AppType.meta.copyWith(color: context.textTertiary),
                ),
                const Spacer(),
                Text(
                  'TARGET ${settings.kcalTarget}',
                  style: AppType.metaSm.copyWith(color: context.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  totals.kcal.round().toString(),
                  key: const Key('diet-kcal-today'),
                  style: AppType.dataHero.copyWith(color: context.textPrimary),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '/ ${settings.kcalTarget} kcal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.meta.copyWith(color: context.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ProgressRule(
              key: const Key('diet-kcal-scale'),
              value: progress(totals.kcal, settings.kcalTarget.toDouble()),
              segments: 20,
              height: 8,
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              label.toUpperCase(),
              style: AppType.metaSm.copyWith(color: context.textTertiary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ProgressRule(
              value: progress(done, target.toDouble()),
              segments: 10,
              height: 5,
            ),
          ),
          const SizedBox(width: 10),
          Text.rich(
            TextSpan(
              text: done.round().toString(),
              style: AppType.data.copyWith(color: context.textPrimary),
              children: [
                if (target > 0)
                  TextSpan(
                    text: ' / $target g',
                    style: AppType.metaSm.copyWith(color: context.textTertiary),
                  ),
              ],
            ),
          ),
        ],
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

    return LedgerPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'STEPS',
                  style: AppType.meta.copyWith(color: context.textTertiary),
                ),
                const Spacer(),
                Text.rich(
                  TextSpan(
                    text: '$steps',
                    style: AppType.dataLg.copyWith(color: context.textPrimary),
                    children: [
                      TextSpan(
                        text: ' / ${settings.stepsTarget} steps',
                        style: AppType.metaSm.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ProgressRule(
              key: const Key('diet-steps-scale'),
              value: progress(
                steps.toDouble(),
                settings.stepsTarget.toDouble(),
              ),
              segments: 20,
              height: 8,
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
    unawaited(
      addWaterMl(db, day, ml).then((_) {
        live.refresh();
        if (messenger == null) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('+$ml ml water'),
            duration: const Duration(seconds: 4),
            persist: false,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () =>
                  unawaited(addWaterMl(db, ref.read(todayKeyProvider), -ml)),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(todayKeyProvider);
    final metric = ref.watch(dayMetricProvider(day)).value;
    final settings = ref.watch(settingsProvider);
    final waterMl = metric?.waterMl ?? 0;

    return LedgerPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'WATER',
                  style: AppType.meta.copyWith(color: context.textTertiary),
                ),
                const Spacer(),
                Text.rich(
                  TextSpan(
                    text: '$waterMl',
                    style: AppType.dataLg.copyWith(color: context.textPrimary),
                    children: [
                      TextSpan(
                        text: ' / ${settings.waterTargetMl} ml',
                        style: AppType.metaSm.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.water_drop,
                  size: 14,
                  color: context.accent.withValues(
                    alpha: waterMl == 0 ? 0.5 : 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ProgressRule(
                    key: const Key('diet-water-scale'),
                    value: progress(
                      waterMl.toDouble(),
                      settings.waterTargetMl.toDouble(),
                    ),
                    segments: 20,
                    height: 8,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_pct(waterMl, settings.waterTargetMl)}%',
                  style: AppType.dataSm.copyWith(color: context.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _QuickAddRow(onTap: (ml) => _tap(context, ref, ml)),
          ],
        ),
      ),
    );
  }
}

/// Three hairline quick-add keys (+100 / +250 / +500 ml).
class _QuickAddRow extends StatelessWidget {
  const _QuickAddRow({required this.onTap});

  final ValueChanged<int> onTap;

  static const _amounts = [100, 250, 500];

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('diet-water-segments'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: context.border),
        borderRadius: BorderRadius.circular(AppRadius.data),
      ),
      child: Row(
        children: [
          for (final (i, ml) in _amounts.indexed)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : Border(left: BorderSide(color: context.border)),
                ),
                child: InkWell(
                  onTap: () => onTap(ml),
                  splashColor: context.accent.withValues(alpha: 0.06),
                  child: SizedBox(
                    height: 42,
                    child: Center(
                      child: Text(
                        '+$ml',
                        style: AppType.data.copyWith(
                          color: context.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------- section chrome --------------------------

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.index,
    required this.title,
    this.meta,
    this.action,
  });

  final String index;
  final String title;
  final String? meta;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(index, style: AppType.meta.copyWith(color: context.textTertiary)),
        const SizedBox(width: 8),
        Container(
          width: 14,
          height: 1,
          color: context.textTertiary.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.h2.copyWith(color: context.textPrimary),
          ),
        ),
        if (meta != null) ...[
          const SizedBox(width: 8),
          Text(
            meta!.toUpperCase(),
            style: AppType.metaSm.copyWith(color: context.textTertiary),
          ),
        ],
        if (action != null) ...[const SizedBox(width: 10), action!],
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({super.key, required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.data),
        splashColor: context.accent.withValues(alpha: 0.08),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: context.border),
            borderRadius: BorderRadius.circular(AppRadius.data),
          ),
          child: Center(
            child: LedgerGlyph(
              LedgerGlyphType.plus,
              size: 16,
              color: context.accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return LedgerPanel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppType.bodySm.copyWith(color: context.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const LedgerPanel(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 58,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
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
        style: AppType.body.copyWith(
          color: context.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${_servings(log.servings)} · $time',
        style: AppType.metaSm.copyWith(color: context.textTertiary),
      ),
      leading: IconButton(
        key: Key('diet-log-delete-${log.id}'),
        icon: Icon(Icons.close_rounded, size: 20, color: context.textTertiary),
        onPressed: () {
          foodRepo.deleteLog(log.id);
          final messenger = ScaffoldMessenger.maybeOf(context);
          if (messenger == null) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text('Removed ${log.name}'),
              duration: const Duration(seconds: 4),
              persist: false,
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => foodRepo.restoreLog(log.id),
              ),
            ),
          );
        },
      ),
      trailing: Text(
        '${log.kcal.round()} kcal',
        style: AppType.data.copyWith(
          color: context.textPrimary,
          fontWeight: FontWeight.w600,
        ),
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
        style: AppType.body.copyWith(
          color: context.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'per $servingLabel · ${food.kcal.round()} kcal · '
        'P ${food.proteinG.round()} / C ${food.carbsG.round()} / '
        'F ${food.fatG.round()} g',
        style: AppType.metaSm.copyWith(
          color: context.textTertiary,
          height: 1.4,
        ),
      ),
      trailing: IconButton(
        key: Key('diet-food-edit-${food.id}'),
        icon: Icon(Icons.edit_outlined, size: 20, color: context.textTertiary),
        onPressed: () => unawaited(showFoodEditorSheet(context, food: food)),
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
        messenger.showSnackBar(
          SnackBar(
            content: Text('Logged ${food.name} · 1 serving'),
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
}
