import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import '../../core/utils/day_key.dart';

/// Records [kg] as today's bodyweight — the capture side of the weight
/// trend (Round 6).
///
/// One row per local calendar day: saving a corrected weight the same
/// day updates the point in place. `id` is the measurement day, but
/// `updatedAt` is the wall clock of the edit — the LWW/fetch timestamp
/// must move *now*, or a correction to an old day could never win
/// remotely. Called by the Profile bodyweight field whenever the value
/// actually changes.
Future<void> logBodyWeight(
  AppDatabase db,
  double kg, {
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  return db.bodyMetrics.insertOnConflictUpdate(BodyMetricsCompanion.insert(
    id: dayKey(at),
    weightKg: Value(kg),
    updatedAt: DateTime.now().toUtc(),
  ));
}
