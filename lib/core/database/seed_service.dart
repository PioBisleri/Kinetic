import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'database.dart';

/// Loads the bundled muscle-group + exercise catalog into SQLite on first
/// launch, so the app is fully usable with zero network.
class SeedService {
  SeedService(this._db);

  final AppDatabase _db;

  Future<void> ensureSeeded() async {
    final existing = await (_db.select(_db.exercises)..limit(1)).get();
    if (existing.isNotEmpty) return;

    final musclesRaw = jsonDecode(
      await rootBundle.loadString('assets/seed/muscle_groups.json'),
    ) as Map<String, dynamic>;
    final exercisesRaw = jsonDecode(
      await rootBundle.loadString('assets/seed/exercises.json'),
    ) as Map<String, dynamic>;

    await _db.transaction(() async {
      // ---- muscle groups (both leaf muscles and display parents) ----
      // Catalog rows are content, not user edits: pin updatedAt/syncedAt to
      // a fixed epoch so fresh installs start "already synced" and don't
      // upload the whole catalog on the first Phase 7 sync. (Installs seeded
      // before this rule push their catalog once — harmless and arguably
      // beneficial: it repairs remote rows.)
      final now = DateTime.utc(2020, 1, 1);

      for (final m in musclesRaw['muscles'] as List) {
        final map = m as Map<String, dynamic>;
        await _db.into(_db.muscleGroups).insertOnConflictUpdate(
              MuscleGroupsCompanion.insert(
                id: map['id'] as String,
                name: map['name'] as String,
                parentId: Value(map['parent'] as String?),
                heatmapNodes: Value(jsonEncode(map['heatmap_nodes'])),
                orderIndex: Value((map['order'] as num?)?.toInt() ?? 0),
                updatedAt: now,
                syncedAt: Value(now),
              ),
            );
      }

      // Parent display groups (chest/back/shoulders/arms/core/legs) exist as
      // muscle_groups rows too, with no heatmap nodes — used by analytics
      // rollup. A group whose id is already a leaf (chest) shares that leaf's
      // row: skip it, or the conflict-update would clobber the leaf's
      // heatmap nodes and ordering (the heat map reads heatmap_nodes from
      // this table).
      final leafIds = <String>{
        for (final m in musclesRaw['muscles'] as List)
          (m as Map<String, dynamic>)['id'] as String,
      };

      for (final g in musclesRaw['groups'] as List) {
        final map = g as Map<String, dynamic>;
        if (leafIds.contains(map['id'] as String)) continue;
        await _db.into(_db.muscleGroups).insertOnConflictUpdate(
              MuscleGroupsCompanion.insert(
                id: map['id'] as String,
                name: map['name'] as String,
                heatmapNodes: const Value('[]'),
                orderIndex: Value(-1),
                updatedAt: now,
                syncedAt: Value(now),
              ),
            );
      }

      // ---- exercises + weighted muscle contributions ----
      for (final e in exercisesRaw['exercises'] as List) {
        final map = e as Map<String, dynamic>;
        final primary = map['primary'] as String;
        final muscles = (map['muscles'] as Map<String, dynamic>).cast<String, num>();
        final metric =
            (map['metric'] as String?) ?? 'weight_reps';

        await _db.into(_db.exercises).insertOnConflictUpdate(
              ExercisesCompanion.insert(
                id: map['id'] as String,
                name: map['name'] as String,
                mechanics: map['mechanics'] as String,
                forceType: Value(map['force'] as String?),
                category: Value(map['category'] as String),
                primaryMuscleId: primary,
                equipment: Value(jsonEncode(map['equipment'] ?? const [])),
                defaultMetric: Value(metric),
                isCustom: const Value(false),
                updatedAt: now,
                syncedAt: Value(now),
              ),
            );

        for (final entry in muscles.entries) {
          await _db.into(_db.exerciseMuscleMap).insertOnConflictUpdate(
                ExerciseMuscleMapCompanion.insert(
                  exerciseId: map['id'] as String,
                  muscleId: entry.key,
                  contribution: Value(entry.value.toDouble()),
                  role: Value(entry.key == primary ? 'primary' : 'secondary'),
                ),
              );
        }
      }
    });
  }
}
