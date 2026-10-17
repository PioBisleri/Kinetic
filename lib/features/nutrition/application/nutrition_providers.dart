import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import 'food_repository.dart';
import '../domain/food_math.dart';

/// The user's food library, name-ordered (tombstones filtered out).
final foodLibraryProvider = StreamProvider<List<Food>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.foods.select()
        ..where((f) => f.deletedAt.isNull())
        ..orderBy([(f) => OrderingTerm.asc(f.name)]))
      .watch();
});

/// Every (non-tombstoned) food logged on [dayKey], newest first.
final foodLogsProvider = StreamProvider.family<List<FoodLog>, String>(
  (ref, dayKey) {
    final db = ref.watch(databaseProvider);
    return (db.foodLogs.select()
          ..where((l) =>
              l.dayKey.equals(dayKey) &
              l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm.desc(l.loggedAt)]))
        .watch();
  },
);

/// Daily macro totals for [dayKey] — pure derivation over the log rows.
final macroTotalsProvider =
    Provider.family<MacroTotals, String>((ref, dayKey) {
  final logs = ref.watch(foodLogsProvider(dayKey)).value;
  return logs == null ? MacroTotals.zero : sum(logs);
});

/// The database-backed repository — created lazily, cheap to construct.
final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => FoodRepository(ref.watch(databaseProvider)),
);
