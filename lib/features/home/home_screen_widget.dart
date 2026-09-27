import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/settings/settings.dart';
import '../../core/utils/weight_units.dart';
import '../analytics/domain/analytics_math.dart';

/// Android home-screen widget (Round 5): this week's volume, the streak,
/// and the next-up routine.
///
/// [computeWidgetStats] is pure DB → strings (unit-testable); the numbers
/// mirror the app's own — `weekStartOf`/`dailyStreak` math from
/// analytics_math, same kg-canonical storage. [updateHomeScreenWidget]
/// writes them through home_widget and asks the launcher to redraw; it is
/// best-effort and never throws — the widget is cosmetic.
class HomeWidgetStats {
  const HomeWidgetStats({
    required this.volume,
    required this.streak,
    required this.routine,
  });

  final String volume; // '12,450 kg'
  final String streak; // '4 weeks'
  final String routine; // 'Push Day' | 'No routines yet'
}

/// Formatted widget strings as of [now]: finished workouts since the
/// current week's Monday sum into the volume, the streak counts
/// consecutive trained weeks (all time), and the first routine in display
/// order is "next up".
Future<HomeWidgetStats> computeWidgetStats(
  AppDatabase db, {
  DateTime? now,
  UnitSystem unit = UnitSystem.kg,
}) async {
  final at = now ?? DateTime.now();
  final weekStart = weekStartOf(at);

  final workouts = await (db.workouts.select()
        ..where((w) => w.status.equals('completed')))
      .get();
  var weekVolumeKg = 0.0;
  final days = <DateTime>{};
  for (final w in workouts) {
    days.add(dayOf(w.startedAt));
    if (!w.startedAt.isBefore(weekStart)) weekVolumeKg += w.totalVolume;
  }

  final routines = await (db.routines.select()
        ..orderBy([
          (r) => OrderingTerm.asc(r.orderIndex),
          (r) => OrderingTerm.asc(r.name),
        ]))
      .get();

  // Same display snap as the app: 0.5 lb steps, grouped thousands.
  final volume = unit == UnitSystem.kg
      ? weekVolumeKg
      : (kgToDisplay(weekVolumeKg, unit) * 2).round() / 2;
  final streak = weeklyStreak(days, now: at);

  return HomeWidgetStats(
    volume: '${NumberFormat.decimalPattern().format(volume)} ${unitLabel(unit)}',
    streak: streak == 1 ? '1 week' : '$streak weeks',
    routine: routines.isEmpty ? 'No routines yet' : routines.first.name,
  );
}

/// Persist the stats and trigger a redraw of every placed widget.
/// Swallows every error (missing channel in tests, no widget placed, …).
Future<void> updateHomeScreenWidget(
  AppDatabase db,
  UnitSystem unit, {
  DateTime? now,
}) async {
  try {
    final stats = await computeWidgetStats(db, now: now, unit: unit);
    await HomeWidget.saveWidgetData<String>('volume', stats.volume);
    await HomeWidget.saveWidgetData<String>('streak', stats.streak);
    await HomeWidget.saveWidgetData<String>('routine', stats.routine);
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.kinetic.kinetic.KineticWidgetProvider',
    );
  } catch (e) {
    debugPrint('home widget update failed: $e');
  }
}
