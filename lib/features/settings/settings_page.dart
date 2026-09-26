import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/weekly_reminder_service.dart';
import '../../core/settings/settings.dart';
import '../../core/utils/rest_format.dart';
import '../../core/widgets/section_card.dart';
import 'sync_section.dart';

const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _fmtTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:'
    '${minute.toString().padLeft(2, '0')}';

/// App settings — split out of Profile so the profile page stays about
/// the body and the data (units/appearance/reminders/sync live here).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(title: 'Units', children: [
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
          SectionCard(title: 'Sync', children: [const SyncSection()]),
          const SizedBox(height: 16),
          SectionCard(title: 'Appearance', children: [
            SwitchListTile(
              key: const Key('dark-mode-toggle'),
              title: const Text('Dark mode'),
              subtitle: const Text('Kinetic defaults to dark'),
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (dark) => notifier
                  .setThemeMode(dark ? ThemeMode.dark : ThemeMode.light),
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
          SectionCard(title: 'Reminders', children: [
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
          SectionCard(title: 'Rest', children: [
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Routine and exercise overrides win over these defaults.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ]),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

String _fmtRest(int seconds) => formatRest(seconds);

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
