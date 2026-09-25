import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/database/database_providers.dart';
import '../../core/export/export_service.dart';
import '../../core/notifications/weekly_reminder_service.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/weight_units.dart';
import 'sync_section.dart';

const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _fmtTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:'
    '${minute.toString().padLeft(2, '0')}';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: 'Units', children: [
            ListTile(
              title: const Text('Weight units'),
              trailing: SegmentedButton<UnitSystem>(
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
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Body', children: [
            ListTile(
              leading: const Icon(Icons.monitor_weight_outlined),
              title: const Text('Bodyweight'),
              subtitle:
                  const Text('Powers Muscle Grade strength scores'),
              trailing: SizedBox(width: 120, child: _BodyweightField()),
            ),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Sync', children: [const SyncSection()]),
          const SizedBox(height: 16),
          _Section(title: 'Appearance', children: [
            SwitchListTile(
              key: const Key('dark-mode-toggle'),
              title: const Text('Dark mode'),
              subtitle: const Text('Kinetic defaults to dark'),
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (dark) =>
                  notifier.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light),
            ),
            if (settings.themeMode == ThemeMode.dark)
              SwitchListTile(
                key: const Key('amoled-black-toggle'),
                title: const Text('AMOLED black'),
                subtitle: const Text('True-black backgrounds save battery'),
                value: settings.amoledBlack,
                onChanged: notifier.setAmoledBlack,
              ),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Reminders', children: [
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
                          await ref.read(weeklyReminderProvider).schedule(
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
                    _fmtTime(settings.reminderHour, settings.reminderMinute)),
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
                  await ref.read(weeklyReminderProvider).schedule(
                        weekday: settings.reminderWeekday,
                        hour: picked.hour,
                        minute: picked.minute,
                      );
                },
              ),
            ],
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Privacy', children: [
            const ListTile(
              leading: Icon(Icons.lock_outline_rounded),
              title: Text('Fully private'),
              subtitle: Text(
                'No friends, no followers, no feed. Your data stays on this '
                'device and your own encrypted backup.',
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Data', children: [
            ListTile(
              leading: const Icon(Icons.data_object_rounded),
              title: const Text('Export JSON backup'),
              subtitle: const Text('Profile, routines and full history'),
              onTap: () => _export(ref, ExportKind.json),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Export CSV'),
              subtitle: const Text('Every set — for spreadsheets (weights in kg)'),
              onTap: () => _export(ref, ExportKind.csv),
            ),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'About', children: [
            ListTile(
              leading: Icon(Icons.info_outline,
                  color: context.textSecondary),
              title: const Text('Kinetic'),
              subtitle: const Text('Version 0.1.0 · offline-first'),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _export(WidgetRef ref, ExportKind kind) async {
    try {
      final service = ExportService(ref.read(databaseProvider));
      if (kind == ExportKind.json) {
        await service.shareJsonBackup();
      } else {
        await service.shareSetsCsv();
      }
    } catch (e) {
      // Share sheet dismissed / temp write failed — the export is best-effort.
      debugPrint('Export failed: $e');
    }
  }
}

enum ExportKind { json, csv }

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: context.textTertiary,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Bodyweight input, shown in display units and stored in kg on the local
/// profile row. Hydration follows the profile stream until the user edits.
class _BodyweightField extends ConsumerStatefulWidget {
  const _BodyweightField();

  @override
  ConsumerState<_BodyweightField> createState() => _BodyweightFieldState();
}

class _BodyweightFieldState extends ConsumerState<_BodyweightField> {
  final _controller = TextEditingController();
  UnitSystem? _shownUnit;
  bool _dirty = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _hydrate(double? kg, UnitSystem unit) {
    if (_dirty) return;
    _shownUnit = unit;
    final text = kg == null ? '' : formatWeight(kg, unit);
    if (_controller.text != text) _controller.text = text;
  }

  Future<void> _save(String text, UnitSystem unit) async {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    if (value == null || value <= 0 || value > 400) return; // ignore garbage
    final kg = displayToKg(value, unit);
    final db = ref.read(databaseProvider);
    _dirty = false; // stream emit below writes back the canonical display
    await db.profiles.insertOnConflictUpdate(ProfilesCompanion.insert(
      id: 'local',
      updatedAt: DateTime.now(),
      bodyweightKg: Value(kg),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(settingsProvider).unit;
    final kg = ref.watch(profileProvider).value?.bodyweightKg;

    // First build or a unit toggle → reformat from the stored kg.
    if (!_dirty && _shownUnit != unit) _hydrate(kg, unit);
    // Profile rows arriving later (or our own save) → keep text canonical.
    ref.listen(
      profileProvider,
      (prev, next) => _hydrate(next.value?.bodyweightKg, unit),
    );

    return TextField(
      key: const Key('bodyweight-input'),
      controller: _controller,
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d?)?$')),
      ],
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        suffixText: unit == UnitSystem.lbs ? 'lb' : 'kg',
        suffixStyle: TextStyle(
            fontSize: 12, color: context.textTertiary),
      ),
      onChanged: (_) => _dirty = true,
      onSubmitted: (text) => _save(text, unit),
    );
  }
}
