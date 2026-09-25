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
  });

  final UnitSystem unit;
  final ThemeMode themeMode;

  /// Which plates the gym actually has — independent of display units.
  final bool plateSetMetric;
  final bool microLoading; // include 1.25 / 0.5 plates

  SettingsState copyWith({
    UnitSystem? unit,
    ThemeMode? themeMode,
    bool? plateSetMetric,
    bool? microLoading,
  }) =>
      SettingsState(
        unit: unit ?? this.unit,
        themeMode: themeMode ?? this.themeMode,
        plateSetMetric: plateSetMetric ?? this.plateSetMetric,
        microLoading: microLoading ?? this.microLoading,
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
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
