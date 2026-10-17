import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/utils/day_key.dart';

/// Today's local day key — re-evaluated whenever anything watches it. The
/// drift stream underneath cannot know a day has changed without a
/// poke, so the widget also refreshes on lifecycle resume (mirrors the
/// home widget's handling in app.dart).
final todayKeyProvider = Provider<String>((ref) => dayKey(DateTime.now()));

/// The daily health row for [dayKey] (weight / water / steps columns).
final dayMetricProvider =
    StreamProvider.family<BodyMetric?, String>((ref, dayKey) {
  final db = ref.watch(databaseProvider);
  return (db.bodyMetrics.select()..where((b) => b.id.equals(dayKey)))
      .watchSingleOrNull();
});

/// Body-metrics write that merges the water column — never clobbers a
/// weigh-in or the step count logged the same day. Negative deltas clamp
/// at 0 (undo delete of a quick-log tap).
///
/// Returns false when there was nothing to change; true otherwise.
Future<bool> addWaterMl(
  AppDatabase db,
  String dayKey,
  int deltaMl,
) async {
  final existing = await db.bodyMetricOnce(dayKey);
  final current = existing?.waterMl ?? 0;
  final next = (current + deltaMl).clamp(0, 1 << 20);
  if (next == current) return false;
  final now = DateTime.now().toUtc();
  final row = existing == null
      ? BodyMetric(id: dayKey, updatedAt: now)
          .copyWith(waterMl: Value(next), syncedAt: const Value(null))
      : existing.copyWith(
          waterMl: Value(next),
          updatedAt: now,
          syncedAt: const Value(null),
        );
  await db.bodyMetrics.insertOnConflictUpdate(row.toCompanion(false));
  return true;
}
