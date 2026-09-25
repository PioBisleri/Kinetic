import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';

/// One exercise slot inside a routine as edited by the builder UI.
class RoutineDraft {
  const RoutineDraft({
    required this.exerciseId,
    required this.targetSets,
    required this.targetReps,
    this.targetWeight,
    this.restSeconds = 90,
    this.isWarmup = false,
    this.linkNext = false,
  });

  final String exerciseId;
  final int targetSets;
  final int targetReps;

  /// Planned load, ALWAYS in kg (nullable = "bring your usual").
  final double? targetWeight;
  final int restSeconds;
  final bool isWarmup;

  /// Display-only flag from the builder; converted to concrete
  /// `supersetGroup` integers on save.
  final bool linkNext;
}

/// Local-first persistence for routines + their exercise slots.
///
/// Save semantics: the routine row is upserted and its children are
/// replaced wholesale inside one transaction (routines are small; this
/// keeps ordering/groups trivially consistent). Children get fresh ids
/// per save — fine locally, and the Phase 7 sync engine upserts children
/// by `routine_id` anyway.
class RoutineRepository {
  RoutineRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Future<String> saveRoutine({
    String? id,
    required String name,
    required List<RoutineDraft> entries,
  }) async {
    final now = DateTime.now();
    final routineId = id ?? _uuid.v4();

    final existing =
        await (_db.routines.select()..where((r) => r.id.equals(routineId)))
            .getSingleOrNull();
    var orderIndex = existing?.orderIndex;
    if (orderIndex == null) {
      final all = await _db.routines.select().get();
      orderIndex = all.isEmpty
          ? 0
          : all.map((r) => r.orderIndex).reduce((a, b) => a > b ? a : b) + 1;
    }

    await _db.routines.insertOnConflictUpdate(RoutinesCompanion.insert(
      id: routineId,
      userId: 'local', // real uid injected by auth in Phase 7
      name: name,
      orderIndex: Value(orderIndex),
      updatedAt: now,
    ));

    final groups = _computeGroups(entries);

    await _db.transaction(() async {
      await (_db.routineExercises.delete()
            ..where((e) => e.routineId.equals(routineId)))
          .go();
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        await _db.routineExercises.insertOnConflictUpdate(
            RoutineExercisesCompanion.insert(
          id: _uuid.v4(),
          routineId: routineId,
          exerciseId: e.exerciseId,
          orderIndex: i,
          supersetGroup: Value(groups[i]),
          targetSets: Value(e.targetSets),
          targetReps: Value(e.targetReps),
          targetWeight: Value(e.targetWeight),
          restSeconds: Value(e.restSeconds),
          isWarmup: Value(e.isWarmup),
          updatedAt: now,
        ));
      }
    });

    return routineId;
  }

  /// Soft-deletes the routine and its children (tombstones for Phase 7).
  Future<void> deleteRoutine(String id) async {
    final now = DateTime.now();
    await (_db.routines.update()..where((r) => r.id.equals(id)))
        .write(RoutinesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
    await (_db.routineExercises.update()
          ..where((e) => e.routineId.equals(id)))
        .write(RoutineExercisesCompanion(
            deletedAt: Value(now), updatedAt: Value(now)));
  }

  /// A run of consecutive `linkNext` entries forms one superset group:
  /// [A(link), B(link), C, D(link), E] → A,B,C group 1; D,E group 2.
  List<int?> _computeGroups(List<RoutineDraft> entries) {
    final groups = List<int?>.filled(entries.length, null);
    var nextGroup = 1;
    var i = 0;
    while (i < entries.length) {
      var j = i;
      while (j < entries.length - 1 && entries[j].linkNext) {
        j++;
      }
      if (j > i) {
        for (var k = i; k <= j; k++) {
          groups[k] = nextGroup;
        }
        nextGroup++;
      }
      i = j + 1;
    }
    return groups;
  }
}

final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => RoutineRepository(ref.watch(databaseProvider)),
);
