import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';

/// Routine + aggregate counts for the list cards.
class RoutineCard {
  const RoutineCard({
    required this.routine,
    required this.exerciseCount,
    required this.targetSetCount,
  });

  final Routine routine;
  final int exerciseCount;
  final int targetSetCount;
}

/// Reactive over both `routines` and `routine_exercises` so cards update
/// when children change (drift streams only cover their own table).
final routinesProvider = StreamProvider<List<RoutineCard>>((ref) {
  final db = ref.watch(databaseProvider);
  late final StreamController<List<RoutineCard>> controller;

  Future<void> load() async {
    if (controller.isClosed) return;
    final routines = await (db.routines.select()
          ..where((r) => r.deletedAt.isNull())
          ..orderBy([
            (r) => OrderingTerm.asc(r.orderIndex),
            (r) => OrderingTerm.asc(r.name),
          ]))
        .get();
    final children = await (db.routineExercises.select()
          ..where((e) => e.deletedAt.isNull()))
        .get();

    final counts = <String, (int, int)>{};
    for (final e in children) {
      final cur = counts[e.routineId] ?? (0, 0);
      counts[e.routineId] = (cur.$1 + 1, cur.$2 + e.targetSets);
    }

    controller.add([
      for (final r in routines)
        RoutineCard(
          routine: r,
          exerciseCount: counts[r.id]?.$1 ?? 0,
          targetSetCount: counts[r.id]?.$2 ?? 0,
        ),
    ]);
  }

  controller = StreamController<List<RoutineCard>>(onListen: () {
    load();
    final subs = <StreamSubscription<dynamic>>[
      db.routines.select().watch().listen((_) => load()),
      db.routineExercises.select().watch().listen((_) => load()),
    ];
    controller.onCancel = () async {
      await Future.wait(subs.map((s) => s.cancel()));
    };
  });

  return controller.stream;
});

/// One routine slot joined with its catalog exercise.
class RoutineEntry {
  const RoutineEntry({required this.row, required this.exercise});

  final RoutineExercise row; // drift data class (singular)
  final Exercise exercise;
}

class RoutineDetail {
  const RoutineDetail({required this.routine, required this.entries});

  final Routine routine;
  final List<RoutineEntry> entries; // ordered by orderIndex
}

final routineDetailProvider =
    StreamProvider.family<RoutineDetail?, String>((ref, id) {
  final db = ref.watch(databaseProvider);

  final routineStream = (db.routines.select()
        ..where((r) => r.id.equals(id)))
      .watchSingleOrNull();

  return routineStream.asyncMap((routine) async {
    if (routine == null) return null;
    final rows = await (db.routineExercises.select()
          ..where((e) => e.routineId.equals(id) & e.deletedAt.isNull())
          ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
        .get();

    final entries = <RoutineEntry>[];
    for (final row in rows) {
      final exercise = await (db.exercises.select()
            ..where((e) => e.id.equals(row.exerciseId))
            ..limit(1))
          .getSingleOrNull();
      if (exercise != null) {
        entries.add(RoutineEntry(row: row, exercise: exercise));
      }
    }
    return RoutineDetail(routine: routine, entries: entries);
  });
});
