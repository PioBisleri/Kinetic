import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/notifications/weekly_reminder_service.dart';
import '../../core/notifications/water_reminder_service.dart';
import '../../core/ledger/ledger.dart';
import '../../core/settings/settings.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/rest_format.dart';
import '../../core/widgets/app_dialog.dart';
import '../health/live_activity_service.dart';
import 'data_section.dart';
import 'sync_section.dart';

const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Square-ish ledger controls instead of M3's full pill shape.
final ButtonStyle _segmentedStyle = ButtonStyle(
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
    ),
  ),
  visualDensity: VisualDensity.compact,
);

String _fmtTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:'
    '${minute.toString().padLeft(2, '0')}';

/// App settings (Round 9.2 redesign) — grouped cards with section icons:
/// Units → Appearance (theme + accent palette) → Sync (only when sync is
/// built into the binary) → Reminders → Nutrition & Health → Live
/// activity → Rest. Profile stays about the body and the data.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final syncConfigured = ref.watch(supabaseConfiguredProvider);

    return Scaffold(
      appBar: const TailBar(
        title: 'Settings',
        meta: 'Units · rhythm · data',
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
            LedgerGroup(
              title: 'Units',
              children: [
                ListTile(
                  title: const Text('Weight units'),
                  trailing: SegmentedButton<UnitSystem>(
                    style: _segmentedStyle,
                    segments: const [
                      ButtonSegment(value: UnitSystem.kg, label: Text('kg')),
                      ButtonSegment(value: UnitSystem.lbs, label: Text('lbs')),
                    ],
                    selected: {settings.unit},
                    onSelectionChanged: (s) => notifier.setUnit(s.first),
                    showSelectedIcon: false,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Micro-loading plates'),
                  subtitle: const Text('Include 1.25 kg / 2.5 lb plates'),
                  value: settings.microLoading,
                  onChanged: notifier.setMicroLoading,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _AppearanceSection(),
            const SizedBox(height: 20),
            if (syncConfigured) ...[
              const LedgerGroup(title: 'Sync', children: [SyncSection()]),
              const SizedBox(height: 20),
            ],
            const _RemindersSection(),
            const SizedBox(height: 20),
            const _NutritionSection(),
            const SizedBox(height: 20),
            const _LiveActivitySection(),
            const SizedBox(height: 20),
            const _RestSection(),
            const SizedBox(height: 20),
            const DataPrivacyAboutSections(),
          ],
        ),
      ),
    );
  }
}

/// Appearance (Round 9.2): theme mode (Auto / Light / Dark), AMOLED
/// true-black under dark, the accent palette swatches and a one-row
/// reset back to the shipped look.
class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return LedgerGroup(
      title: 'Appearance',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Theme',
                style: AppType.body.copyWith(color: context.textPrimary),
              ),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                key: const Key('theme-mode-segments'),
                style: _segmentedStyle,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_rounded, size: 18),
                    label: Text('Auto'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded, size: 18),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded, size: 18),
                    label: Text('Dark'),
                  ),
                ],
                showSelectedIcon: false,
                selected: {settings.themeMode},
                onSelectionChanged: (s) =>
                    ref.read(settingsProvider.notifier).setThemeMode(s.first),
              ),
            ],
          ),
        ),
        if (settings.themeMode == ThemeMode.dark)
          SwitchListTile(
            key: const Key('amoled-black-toggle'),
            title: const Text('AMOLED black'),
            subtitle: const Text('True-black backgrounds save battery'),
            value: settings.amoledBlack,
            onChanged: notifier.setAmoledBlack,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final palette in AppAccent.all)
                _AccentSwatch(
                  key: Key('accent-${palette.id}'),
                  palette: palette,
                  selected: settings.accent == palette.id,
                  onTap: () => notifier.setAccent(palette.id),
                ),
            ],
          ),
        ),
        ListTile(
          key: const Key('appearance-reset'),
          title: const Text('Reset to default'),
          subtitle: const Text('Dark · AMOLED off · Kinetic teal'),
          leading: const Icon(Icons.restart_alt_rounded),
          onTap: () async {
            final ok = await confirmAction(
              context,
              title: 'Reset appearance?',
              message:
                  'Returns to the shipped look: dark theme, the Kinetic '
                  'teal accent and AMOLED black off.',
              confirmLabel: 'Reset',
            );
            if (ok != true) return;
            await notifier.setThemeMode(ThemeMode.dark);
            await notifier.setAccent(AppAccent.defaultId);
            await notifier.setAmoledBlack(false);
          },
        ),
      ],
    );
  }
}

/// One accent choice — a colored disc with a check once selected.
class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    super.key,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppAccent palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.color,
          border: Border.all(
            color: selected ? context.textPrimary : context.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: selected
            ? Icon(
                Icons.check_rounded,
                size: 20,
                color: onAccent(palette.color),
              )
            : null,
      ),
    );
  }
}

/// Weekly workout reminder (weekday chips + time picker).
class _RemindersSection extends ConsumerWidget {
  const _RemindersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return LedgerGroup(
      title: 'Reminders',
      children: [
        SwitchListTile(
          key: const Key('reminder-toggle'),
          title: const Text('Weekly workout reminder'),
          subtitle: const Text('A nudge when it’s time to train'),
          value: settings.reminderEnabled,
          onChanged: (enabled) async {
            await notifier.setReminderEnabled(enabled);
            final service = ref.read(weeklyReminderProvider);
            if (enabled) {
              await service.schedule(
                weekday: settings.reminderWeekday,
                hour: settings.reminderHour,
                minute: settings.reminderMinute,
              );
            } else {
              await service.cancel();
            }
          },
        ),
        if (settings.reminderEnabled) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var day = 1; day <= 7; day++)
                  ChoiceChip(
                    key: Key('reminder-day-$day'),
                    label: Text(_dayLabels[day - 1]),
                    selected: settings.reminderWeekday == day,
                    onSelected: (_) async {
                      await notifier.setReminderWeekday(day);
                      await ref
                          .read(weeklyReminderProvider)
                          .schedule(
                            weekday: day,
                            hour: settings.reminderHour,
                            minute: settings.reminderMinute,
                          );
                    },
                  ),
              ],
            ),
          ),
          ListTile(
            key: const Key('reminder-time'),
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Time'),
            trailing: Text(
              _fmtTime(settings.reminderHour, settings.reminderMinute),
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: settings.reminderHour,
                  minute: settings.reminderMinute,
                ),
              );
              if (picked == null) return;
              await notifier.setReminderTime(picked.hour, picked.minute);
              await ref
                  .read(weeklyReminderProvider)
                  .schedule(
                    weekday: settings.reminderWeekday,
                    hour: picked.hour,
                    minute: picked.minute,
                  );
            },
          ),
        ],
      ],
    );
  }
}

/// Water reminder + the daily nutrition targets.
class _NutritionSection extends ConsumerWidget {
  const _NutritionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return LedgerGroup(
      title: 'Nutrition & Health',
      children: [
        SwitchListTile(
          key: const Key('water-reminder-toggle'),
          title: const Text('Water reminder'),
          subtitle: const Text('Recurring nudge to drink water'),
          value: settings.waterReminderEnabled,
          onChanged: (enabled) async {
            await notifier.setWaterReminder(enabled: enabled);
            final service = ref.read(waterReminderProvider);
            if (enabled) {
              await service.schedule(
                startHour: settings.waterStartHour,
                endHour: settings.waterEndHour,
                intervalMin: settings.waterIntervalMin,
              );
            } else {
              await service.cancel();
            }
          },
        ),
        if (settings.waterReminderEnabled) ...[
          ListTile(
            key: const Key('water-start'),
            leading: const Icon(Icons.wb_twilight_outlined),
            title: const Text('Start'),
            trailing: Text(_fmtTime(settings.waterStartHour, 0)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: settings.waterStartHour,
                  minute: 0,
                ),
              );
              if (picked == null) return;
              await notifier.setWaterReminder(
                enabled: true,
                startHour: picked.hour,
                endHour: settings.waterEndHour,
                intervalMin: settings.waterIntervalMin,
              );
              await ref
                  .read(waterReminderProvider)
                  .schedule(
                    startHour: picked.hour,
                    endHour: settings.waterEndHour,
                    intervalMin: settings.waterIntervalMin,
                  );
            },
          ),
          ListTile(
            key: const Key('water-end'),
            leading: const Icon(Icons.nightlight_outlined),
            title: const Text('End'),
            trailing: Text(_fmtTime(settings.waterEndHour, 0)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: settings.waterEndHour, minute: 0),
              );
              if (picked == null) return;
              await notifier.setWaterReminder(
                enabled: true,
                startHour: settings.waterStartHour,
                endHour: picked.hour,
                intervalMin: settings.waterIntervalMin,
              );
              await ref
                  .read(waterReminderProvider)
                  .schedule(
                    startHour: settings.waterStartHour,
                    endHour: settings.waterEndHour,
                    intervalMin: settings.waterIntervalMin,
                  );
            },
          ),
          ListTile(
            title: const Text('Every'),
            trailing: Text('${settings.waterIntervalMin} min'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final min in [30, 60, 90, 120, 180, 240])
                  ChoiceChip(
                    key: Key('water-interval-$min'),
                    label: Text('$min m'),
                    selected: settings.waterIntervalMin == min,
                    onSelected: (_) async {
                      await notifier.setWaterReminder(
                        enabled: true,
                        intervalMin: min,
                      );
                      await ref
                          .read(waterReminderProvider)
                          .schedule(
                            startHour: settings.waterStartHour,
                            endHour: settings.waterEndHour,
                            intervalMin: min,
                          );
                    },
                  ),
              ],
            ),
          ),
        ],
        _TargetRow(
          id: 'target-kcal',
          title: 'Daily kcal',
          value: settings.kcalTarget,
          save: notifier.setKcalTarget,
        ),
        _TargetRow(
          id: 'target-protein',
          title: 'Protein (g)',
          value: settings.proteinTargetG,
          save: notifier.setProteinTarget,
        ),
        _TargetRow(
          id: 'target-carbs',
          title: 'Carbs (g)',
          value: settings.carbsTargetG,
          save: notifier.setCarbsTarget,
        ),
        _TargetRow(
          id: 'target-fat',
          title: 'Fat (g)',
          value: settings.fatTargetG,
          save: notifier.setFatTarget,
        ),
        _TargetRow(
          id: 'target-water',
          title: 'Water (ml)',
          value: settings.waterTargetMl,
          save: (ml) async {
            await notifier.setWaterTarget(ml);
            await ref.read(liveActivityControllerProvider).refresh();
          },
        ),
        _TargetRow(
          id: 'target-steps',
          title: 'Steps',
          value: settings.stepsTarget,
          save: (steps) async {
            await notifier.setStepsTarget(steps);
            await ref.read(liveActivityControllerProvider).refresh();
          },
        ),
      ],
    );
  }
}

/// Live activity notification (Round 9) — the toggle arms/disarms a native
/// foreground service; the checkboxes pick the notification's rows, and
/// the battery row keeps it alive under OEM power management.
class _LiveActivitySection extends ConsumerWidget {
  const _LiveActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return LedgerGroup(
      title: 'Live activity',
      children: [
        SwitchListTile(
          key: const Key('settings-live-toggle'),
          title: const Text('Live activity notification'),
          subtitle: const Text(
            'Persistent steps, calories and hydration summary',
          ),
          value: settings.liveEnabled,
          onChanged: (enabled) async {
            // Runtime gates (the two permissions the service needs):
            // activity-recognition is the requirement for the step-counter
            // sensor on Android 10+ (missing it left the notification at 0
            // steps forever), notifications just make it visible on 13+.
            if (enabled) {
              try {
                await Permission.activityRecognition.request();
                await Permission.notification.request();
              } catch (_) {}
            }
            await notifier.setLiveEnabled(enabled);
            await ref.read(liveActivityControllerProvider).apply();
          },
        ),
        if (settings.liveEnabled) ...[
          CheckboxListTile(
            key: const Key('settings-live-steps'),
            dense: true,
            title: const Text('Steps'),
            value: settings.liveShowSteps,
            onChanged: (on) async {
              await notifier.setLiveShow(steps: on ?? true);
              await ref.read(liveActivityControllerProvider).refresh();
            },
          ),
          CheckboxListTile(
            key: const Key('settings-live-calories'),
            dense: true,
            title: const Text('Calories burned'),
            subtitle: const Text('Steps to kcal with your bodyweight'),
            value: settings.liveShowCalories,
            onChanged: (on) async {
              await notifier.setLiveShow(calories: on ?? true);
              await ref.read(liveActivityControllerProvider).refresh();
            },
          ),
          CheckboxListTile(
            key: const Key('settings-live-hydration'),
            dense: true,
            title: const Text('Hydration'),
            subtitle: const Text("Today's water intake"),
            value: settings.liveShowHydration,
            onChanged: (on) async {
              await notifier.setLiveShow(hydration: on ?? true);
              await ref.read(liveActivityControllerProvider).refresh();
            },
          ),
          const _BatteryExemptionRow(),
        ],
      ],
    );
  }
}

/// Battery-optimization exemption (Round 9.1): OEM power managers stop
/// even a specialUse foreground service "due to app idle" unless the app
/// is exempt — this row shows the status and asks the system with its
/// own "allow always running?" dialog.
class _BatteryExemptionRow extends ConsumerStatefulWidget {
  const _BatteryExemptionRow();

  @override
  ConsumerState<_BatteryExemptionRow> createState() =>
      _BatteryExemptionRowState();
}

class _BatteryExemptionRowState extends ConsumerState<_BatteryExemptionRow>
    with WidgetsBindingObserver {
  bool? _exempt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The system dialog returns the user here — re-read the status.
    if (state == AppLifecycleState.resumed) _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _check() async {
    final exempt = await ref.read(liveActivityProvider).batteryExempt();
    if (mounted) setState(() => _exempt = exempt);
  }

  @override
  Widget build(BuildContext context) {
    final exempt = _exempt ?? false;
    return ListTile(
      key: const Key('battery-exemption-row'),
      leading: Icon(
        exempt ? Icons.battery_saver_rounded : Icons.battery_alert_rounded,
        color: exempt ? context.accent : null,
      ),
      title: const Text('Run in background'),
      subtitle: Text(
        exempt
            ? 'Exempted from battery optimization'
            : 'Ask Android to keep this running all day',
      ),
      trailing: exempt
          ? Icon(Icons.check_circle_rounded, color: context.accent, size: 20)
          : const Icon(Icons.arrow_outward_rounded, size: 18),
      onTap: exempt
          ? null
          : () async {
              await ref.read(liveActivityProvider).requestBatteryExempt();
              // Re-check shortly after: the dialog launch is async and
              // the status refresh also happens on resume.
              await Future<void>.delayed(const Duration(milliseconds: 800));
              if (mounted) await _check();
            },
    );
  }
}

/// Rest periods by set type (seconds), −/+ 15 s steppers.
class _RestSection extends ConsumerWidget {
  const _RestSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return LedgerGroup(
      title: 'Rest',
      children: [
        _RestRow(
          id: 'rest-warmup',
          title: 'Warm-up sets',
          value: settings.restWarmupSec,
          onChanged: notifier.setRestWarmup,
        ),
        _RestRow(
          id: 'rest-working',
          title: 'Working & drop sets',
          value: settings.restWorkingSec,
          onChanged: notifier.setRestWorking,
        ),
        _RestRow(
          id: 'rest-failure',
          title: 'Failure sets',
          value: settings.restFailureSec,
          onChanged: notifier.setRestFailure,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Routine and exercise overrides win over these defaults.',
            style: TextStyle(fontSize: 12, color: context.textTertiary),
          ),
        ),
      ],
    );
  }
}

String _fmtRest(int seconds) => formatRest(seconds);

/// One editable daily-target row: label, current value, tap → number
/// entry dialog. Reused for kcal, macros, water and steps.
class _TargetRow extends StatelessWidget {
  const _TargetRow({
    required this.id,
    required this.title,
    required this.value,
    required this.save,
  });

  final String id;
  final String title;
  final int value;
  final ValueChanged<int> save;

  Future<void> _edit(BuildContext context) async {
    final controller = TextEditingController(text: '$value');
    final next = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          key: Key('$id-input'),
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          onSubmitted: (v) => Navigator.of(dialogContext).pop(int.tryParse(v)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (next != null) save(next);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key(id),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: context.textTertiary),
        ],
      ),
      onTap: () async => _edit(context),
    );
  }
}

/// One rest duration row: label, formatted value, −/+ steppers (15 s steps,
/// 0 = timer off … 600 s).
class _RestRow extends StatelessWidget {
  const _RestRow({
    required this.id,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String id;
  final String title;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: Key('$id-minus'),
            icon: const Icon(Icons.remove, size: 18),
            onPressed: value <= 0 ? null : () => onChanged(value - 15),
          ),
          SizedBox(
            width: 56,
            child: Text(
              _fmtRest(value),
              key: Key('$id-value'),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            key: Key('$id-plus'),
            icon: const Icon(Icons.add, size: 18),
            onPressed: value >= 600 ? null : () => onChanged(value + 15),
          ),
        ],
      ),
    );
  }
}
