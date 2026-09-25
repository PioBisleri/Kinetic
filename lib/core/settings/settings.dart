import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Injected in main() after SharedPreferences.getInstance().
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

enum UnitSystem { kg, lbs }

class SettingsState {
  const SettingsState({
    this.unit = UnitSystem.kg,
    this.themeMode = ThemeMode.dark,
    this.plateSetMetric = true,
    this.microLoading = false,
    this.amoledBlack = false,
    this.reminderEnabled = false,
    this.reminderWeekday = DateTime.monday,
    this.reminderHour = 18,
    this.reminderMinute = 0,
  });

  final UnitSystem unit;
  final ThemeMode themeMode;

  /// Which plates the gym actually has — independent of display units.
  final bool plateSetMetric;
  final bool microLoading; // include 1.25 / 0.5 plates

  /// True-black surfaces in dark mode (saves battery on AMOLED panels).
  final bool amoledBlack;

  /// Weekly workout reminder — see [reminderWeekday]/[reminderHour].
  final bool reminderEnabled;
  final int reminderWeekday; // 1 = Mon … 7 = Sun
  final int reminderHour;
  final int reminderMinute;

  SettingsState copyWith({
    UnitSystem? unit,
    ThemeMode? themeMode,
    bool? plateSetMetric,
    bool? microLoading,
    bool? amoledBlack,
    bool? reminderEnabled,
    int? reminderWeekday,
    int? reminderHour,
    int? reminderMinute,
  }) =>
      SettingsState(
        unit: unit ?? this.unit,
        themeMode: themeMode ?? this.themeMode,
        plateSetMetric: plateSetMetric ?? this.plateSetMetric,
        microLoading: microLoading ?? this.microLoading,
        amoledBlack: amoledBlack ?? this.amoledBlack,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderWeekday: reminderWeekday ?? this.reminderWeekday,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
      );
}

class SettingsNotifier extends Notifier<SettingsState> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  SettingsState build() {
    final unitName = _prefs.getString('unit') ?? 'kg';
    final themeName = _prefs.getString('theme') ?? 'dark';
    return SettingsState(
      unit: UnitSystem.values.firstWhere((u) => u.name == unitName,
          orElse: () => UnitSystem.kg),
      themeMode:
          themeName == 'light' ? ThemeMode.light : ThemeMode.dark,
      plateSetMetric: _prefs.getBool('plate_set_metric') ?? true,
      microLoading: _prefs.getBool('micro_loading') ?? false,
      amoledBlack: _prefs.getBool('amoled_black') ?? false,
      reminderEnabled: _prefs.getBool('reminder_enabled') ?? false,
      reminderWeekday: _prefs.getInt('reminder_weekday') ?? DateTime.monday,
      reminderHour: _prefs.getInt('reminder_hour') ?? 18,
      reminderMinute: _prefs.getInt('reminder_minute') ?? 0,
    );
  }

  Future<void> setUnit(UnitSystem unit) async {
    state = state.copyWith(unit: unit);
    await _prefs.setString('unit', unit.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString('theme', mode == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> setPlateSetMetric(bool metric) async {
    state = state.copyWith(plateSetMetric: metric);
    await _prefs.setBool('plate_set_metric', metric);
  }

  Future<void> setMicroLoading(bool enabled) async {
    state = state.copyWith(microLoading: enabled);
    await _prefs.setBool('micro_loading', enabled);
  }

  Future<void> setAmoledBlack(bool enabled) async {
    state = state.copyWith(amoledBlack: enabled);
    await _prefs.setBool('amoled_black', enabled);
  }

  Future<void> setReminderEnabled(bool enabled) async {
    state = state.copyWith(reminderEnabled: enabled);
    await _prefs.setBool('reminder_enabled', enabled);
  }

  Future<void> setReminderWeekday(int weekday) async {
    state = state.copyWith(reminderWeekday: weekday);
    await _prefs.setInt('reminder_weekday', weekday);
  }

  Future<void> setReminderTime(int hour, int minute) async {
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
    await _prefs.setInt('reminder_hour', hour);
    await _prefs.setInt('reminder_minute', minute);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
