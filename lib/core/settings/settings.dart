import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Injected in main() after SharedPreferences.getInstance().
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

enum UnitSystem { kg, lbs }

/// widget/theme picker values — 'system' follows the OS (Round 9.2).
String _serializeTheme(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
      _ => 'dark',
    };

ThemeMode _parseTheme(String raw) => switch (raw) {
      'system' => ThemeMode.system,
      'light' => ThemeMode.light,
      _ => ThemeMode.dark,
    };

class SettingsState {
  const SettingsState({
    this.unit = UnitSystem.kg,
    this.themeMode = ThemeMode.dark,
    this.accent = 'kinetic',
    this.plateSetMetric = true,
    this.microLoading = false,
    this.amoledBlack = false,
    this.reminderEnabled = false,
    this.reminderWeekday = DateTime.monday,
    this.reminderHour = 18,
    this.reminderMinute = 0,
    this.restWarmupSec = 60,
    this.restWorkingSec = 90,
    this.restFailureSec = 120,
    this.kcalTarget = 2500,
    this.proteinTargetG = 150,
    this.carbsTargetG = 250,
    this.fatTargetG = 70,
    this.waterTargetMl = 2500,
    this.waterReminderEnabled = false,
    this.waterStartHour = 9,
    this.waterEndHour = 22,
    this.waterIntervalMin = 60,
    this.stepsTarget = 8000,
    this.liveEnabled = false,
    this.liveShowSteps = true,
    this.liveShowCalories = true,
    this.liveShowHydration = true,
  });

  final UnitSystem unit;
  final ThemeMode themeMode;

  /// Appearance accent palette id (Round 9.2) — see [AppAccent.byId];
  /// 'kinetic' is the shipped default.
  final String accent;

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

  /// Global rest periods by set type, in seconds. Drop sets share
  /// [restWorkingSec]. These are the fallback under the per-exercise and
  /// per-routine overrides.
  final int restWarmupSec;
  final int restWorkingSec;
  final int restFailureSec;

  /// Daily nutrition targets (Round 8). Kcal + macro grams; the /diet
  /// progress bars fire against these.
  final int kcalTarget;
  final int proteinTargetG;
  final int carbsTargetG;
  final int fatTargetG;

  /// Hydration (Round 8): daily intake target in ml plus the reminder
  /// alarm — recurring inside the [waterStartHour]..[waterEndHour] window
  /// (inclusive), spaced [waterIntervalMin] apart.
  final int waterTargetMl;
  final bool waterReminderEnabled;
  final int waterStartHour; // 0..23 inclusive
  final int waterEndHour; // 0..23 inclusive
  final int waterIntervalMin;

  /// Daily step target (Round 8).
  final int stepsTarget;

  /// Live activity notification (Round 9): the persistent foreground
  /// notification with today's live metrics. Native service, armed from
  /// these settings; [liveShow*] pick the notification's rows.
  final bool liveEnabled;
  final bool liveShowSteps;
  final bool liveShowCalories;
  final bool liveShowHydration;

  SettingsState copyWith({
    UnitSystem? unit,
    ThemeMode? themeMode,
    String? accent,
    bool? plateSetMetric,
    bool? microLoading,
    bool? amoledBlack,
    bool? reminderEnabled,
    int? reminderWeekday,
    int? reminderHour,
    int? reminderMinute,
    int? restWarmupSec,
    int? restWorkingSec,
    int? restFailureSec,
    int? kcalTarget,
    int? proteinTargetG,
    int? carbsTargetG,
    int? fatTargetG,
    int? waterTargetMl,
    bool? waterReminderEnabled,
    int? waterStartHour,
    int? waterEndHour,
    int? waterIntervalMin,
    int? stepsTarget,
    bool? liveEnabled,
    bool? liveShowSteps,
    bool? liveShowCalories,
    bool? liveShowHydration,
  }) =>
      SettingsState(
        unit: unit ?? this.unit,
        themeMode: themeMode ?? this.themeMode,
        accent: accent ?? this.accent,
        plateSetMetric: plateSetMetric ?? this.plateSetMetric,
        microLoading: microLoading ?? this.microLoading,
        amoledBlack: amoledBlack ?? this.amoledBlack,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderWeekday: reminderWeekday ?? this.reminderWeekday,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
        restWarmupSec: restWarmupSec ?? this.restWarmupSec,
        restWorkingSec: restWorkingSec ?? this.restWorkingSec,
        restFailureSec: restFailureSec ?? this.restFailureSec,
        kcalTarget: kcalTarget ?? this.kcalTarget,
        proteinTargetG: proteinTargetG ?? this.proteinTargetG,
        carbsTargetG: carbsTargetG ?? this.carbsTargetG,
        fatTargetG: fatTargetG ?? this.fatTargetG,
        waterTargetMl: waterTargetMl ?? this.waterTargetMl,
        waterReminderEnabled: waterReminderEnabled ?? this.waterReminderEnabled,
        waterStartHour: waterStartHour ?? this.waterStartHour,
        waterEndHour: waterEndHour ?? this.waterEndHour,
        waterIntervalMin: waterIntervalMin ?? this.waterIntervalMin,
        stepsTarget: stepsTarget ?? this.stepsTarget,
        liveEnabled: liveEnabled ?? this.liveEnabled,
        liveShowSteps: liveShowSteps ?? this.liveShowSteps,
        liveShowCalories: liveShowCalories ?? this.liveShowCalories,
        liveShowHydration: liveShowHydration ?? this.liveShowHydration,
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
      themeMode: _parseTheme(themeName),
      accent: _prefs.getString('accent') ?? 'kinetic',
      plateSetMetric: _prefs.getBool('plate_set_metric') ?? true,
      microLoading: _prefs.getBool('micro_loading') ?? false,
      amoledBlack: _prefs.getBool('amoled_black') ?? false,
      reminderEnabled: _prefs.getBool('reminder_enabled') ?? false,
      reminderWeekday: _prefs.getInt('reminder_weekday') ?? DateTime.monday,
      reminderHour: _prefs.getInt('reminder_hour') ?? 18,
      reminderMinute: _prefs.getInt('reminder_minute') ?? 0,
      restWarmupSec: _prefs.getInt('rest_warmup_sec') ?? 60,
      restWorkingSec: _prefs.getInt('rest_working_sec') ?? 90,
      restFailureSec: _prefs.getInt('rest_failure_sec') ?? 120,
      kcalTarget: _prefs.getInt('kcal_target') ?? 2500,
      proteinTargetG: _prefs.getInt('protein_target_g') ?? 150,
      carbsTargetG: _prefs.getInt('carbs_target_g') ?? 250,
      fatTargetG: _prefs.getInt('fat_target_g') ?? 70,
      waterTargetMl: _prefs.getInt('water_target_ml') ?? 2500,
      waterReminderEnabled:
          _prefs.getBool('water_reminder_enabled') ?? false,
      waterStartHour: _prefs.getInt('water_start_hour') ?? 9,
      waterEndHour: _prefs.getInt('water_end_hour') ?? 22,
      waterIntervalMin: _prefs.getInt('water_interval_min') ?? 60,
      stepsTarget: _prefs.getInt('steps_target') ?? 8000,
      liveEnabled: _prefs.getBool('live_enabled') ?? false,
      liveShowSteps: _prefs.getBool('live_show_steps') ?? true,
      liveShowCalories: _prefs.getBool('live_show_calories') ?? true,
      liveShowHydration: _prefs.getBool('live_show_hydration') ?? true,
    );
  }

  Future<void> setUnit(UnitSystem unit) async {
    state = state.copyWith(unit: unit);
    await _prefs.setString('unit', unit.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString('theme', _serializeTheme(mode));
  }

  Future<void> setAccent(String id) async {
    state = state.copyWith(accent: id);
    await _prefs.setString('accent', id);
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

  /// Rest periods are clamped to 0 (timer off) … 600 s (10 min).
  Future<void> setRestWarmup(int seconds) async {
    state = state.copyWith(restWarmupSec: seconds.clamp(0, 600));
    await _prefs.setInt('rest_warmup_sec', state.restWarmupSec);
  }

  Future<void> setRestWorking(int seconds) async {
    state = state.copyWith(restWorkingSec: seconds.clamp(0, 600));
    await _prefs.setInt('rest_working_sec', state.restWorkingSec);
  }

  Future<void> setRestFailure(int seconds) async {
    state = state.copyWith(restFailureSec: seconds.clamp(0, 600));
    await _prefs.setInt('rest_failure_sec', state.restFailureSec);
  }

  /// Nutrition targets — clamped to sane ranges (kcal up to 10000, macro
  /// grams up to 2000).
  Future<void> setKcalTarget(int kcal) async {
    state = state.copyWith(kcalTarget: kcal.clamp(0, 10000));
    await _prefs.setInt('kcal_target', state.kcalTarget);
  }

  Future<void> setProteinTarget(int grams) async {
    state = state.copyWith(proteinTargetG: grams.clamp(0, 2000));
    await _prefs.setInt('protein_target_g', state.proteinTargetG);
  }

  Future<void> setCarbsTarget(int grams) async {
    state = state.copyWith(carbsTargetG: grams.clamp(0, 2000));
    await _prefs.setInt('carbs_target_g', state.carbsTargetG);
  }

  Future<void> setFatTarget(int grams) async {
    state = state.copyWith(fatTargetG: grams.clamp(0, 2000));
    await _prefs.setInt('fat_target_g', state.fatTargetG);
  }

  Future<void> setWaterTarget(int ml) async {
    state = state.copyWith(waterTargetMl: ml.clamp(0, 20000));
    await _prefs.setInt('water_target_ml', state.waterTargetMl);
  }

  Future<void> setStepsTarget(int steps) async {
    state = state.copyWith(stepsTarget: steps.clamp(0, 200000));
    await _prefs.setInt('steps_target', state.stepsTarget);
  }

  /// Live activity notification — armed/disarmed by the caller
  /// (settings page toggle → start/stop the native service).
  Future<void> setLiveEnabled(bool enabled) async {
    state = state.copyWith(liveEnabled: enabled);
    await _prefs.setBool('live_enabled', state.liveEnabled);
  }

  Future<void> setLiveShow({
    bool? steps,
    bool? calories,
    bool? hydration,
  }) async {
    state = state.copyWith(
      liveShowSteps: steps ?? state.liveShowSteps,
      liveShowCalories: calories ?? state.liveShowCalories,
      liveShowHydration: hydration ?? state.liveShowHydration,
    );
    await _prefs.setBool('live_show_steps', state.liveShowSteps);
    await _prefs.setBool('live_show_calories', state.liveShowCalories);
    await _prefs.setBool('live_show_hydration', state.liveShowHydration);
  }

  /// Water reminder — clamped window (0..23 h) and 15..240 min interval;
  /// arming the alarm itself is the caller's job (app.dart re-arm path).
  Future<void> setWaterReminder({
    required bool enabled,
    int? startHour,
    int? endHour,
    int? intervalMin,
  }) async {
    state = state.copyWith(
      waterReminderEnabled: enabled,
      waterStartHour: (startHour ?? state.waterStartHour).clamp(0, 23),
      waterEndHour: (endHour ?? state.waterEndHour).clamp(0, 23),
      waterIntervalMin: (intervalMin ?? state.waterIntervalMin).clamp(15, 240),
    );
    await _prefs.setBool('water_reminder_enabled', state.waterReminderEnabled);
    await _prefs.setInt('water_start_hour', state.waterStartHour);
    await _prefs.setInt('water_end_hour', state.waterEndHour);
    await _prefs.setInt('water_interval_min', state.waterIntervalMin);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
