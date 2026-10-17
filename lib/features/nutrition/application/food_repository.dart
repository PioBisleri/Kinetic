import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../domain/food_math.dart';

/// Local-first persistence for the food library and the daily log.
///
/// MirrorsRoutineRepository semantics: every write stamps `updatedAt`
/// and clears `syncedAt` (dirty for the sync engine); deletes are
/// tombstones, never hard removals; `ownerId` is `'local'`
/// until real auth injects a uid.
class FoodRepository {
  FoodRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Snapshot of a [Food] scaled by [servings] — history in [FoodLogs]
  /// never re-reads the library row.
  Future<String> logFood({
    required String dayKey,
    required Food food,
    required double servings,
  }) async {
    final macros = scaleFood(food, servings);
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    await _db
        .into(_db.foodLogs)
        .insert(FoodLogsCompanion.insert(
          id: id,
          dayKey: dayKey,
          name: food.name,
          kcal: macros.kcal,
          proteinG: macros.proteinG,
          carbsG: macros.carbsG,
          fatG: macros.fatG,
          loggedAt: now,
          updatedAt: now,
        ).copyWith(
          servings: Value(servings),
          foodId: Value(food.id),
          syncedAt: const Value(null),
        ));
    return id;
  }

  /// Ad-hoc entry without a library row (e.g. "three eggs"). The stored
  /// kcal defaults to the Atwater formula over the macros, so manual
  /// entries are internally consistent.
  Future<String> logManual({
    required String dayKey,
    required String name,
    required double servings,
    required double proteinG,
    required double carbsG,
    required double fatG,
    double? kcalOverride,
  }) async {
    final macros = MacroTotals(
      kcal: kcalOverride ?? kcalFromMacros(proteinG, carbsG, fatG) * servings,
      proteinG: proteinG * servings,
      carbsG: carbsG * servings,
      fatG: fatG * servings,
    );
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    await _db
        .into(_db.foodLogs)
        .insert(FoodLogsCompanion.insert(
          id: id,
          dayKey: dayKey,
          name: name,
          kcal: macros.kcal,
          proteinG: macros.proteinG,
          carbsG: macros.carbsG,
          fatG: macros.fatG,
          loggedAt: now,
          updatedAt: now,
        ).copyWith(
          servings: Value(servings),
          syncedAt: const Value(null),
        ));
    return id;
  }

  Future<void> deleteLog(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.foodLogs)..where((l) => l.id.equals(id)))
        .write(FoodLogsCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
      syncedAt: const Value(null),
    ));
  }

  /// Undoes a tombstoned log — restores the very same row in place.
  Future<void> restoreLog(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.foodLogs)..where((l) => l.id.equals(id)))
        .write(FoodLogsCompanion(
      deletedAt: const Value(null),
      updatedAt: Value(now),
      syncedAt: const Value(null),
    ));
  }

  // ----------------------------- library ----------------------------------

  /// Creates a library row (or edits an existing one). Passing the `id`
  /// of a tombstoned row resurrects it — old history logs keep pointing
  /// at their `foodId` either way.
  Future<void> saveFood({
    String? id,
    required String name,
    String? brand,
    required double servingSize,
    required String servingUnit,
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) async {
    final now = DateTime.now().toUtc();
    await _db.into(_db.foods).insertOnConflictUpdate(FoodsCompanion.insert(
      id: id ?? _uuid.v4(),
      name: name,
      updatedAt: now,
    ).copyWith(
      brand: Value(brand),
      servingSize: Value(servingSize),
      servingUnit: Value(servingUnit),
      kcal: Value(kcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      isCustom: const Value(true),
      ownerId: const Value('local'),
      deletedAt: const Value(null), // save also un-deletes
      syncedAt: const Value(null),
    ));
  }

  Future<void> deleteFood(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.foods)..where((f) => f.id.equals(id)))
        .write(FoodsCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
      syncedAt: const Value(null),
    ));
  }

  /// Undoes a tombstoned food — restores the row in place.
  Future<void> restoreFood(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.foods)..where((f) => f.id.equals(id)))
        .write(FoodsCompanion(
      deletedAt: const Value(null),
      updatedAt: Value(now),
      syncedAt: const Value(null),
    ));
  }
}
