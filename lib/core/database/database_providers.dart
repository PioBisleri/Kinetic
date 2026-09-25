import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// Family over (category, search) so sheets/pages can watch filtered
/// catalog queries reactively.
final dbExercisesProvider = StreamProvider.autoDispose
    .family<List<Exercise>, ({String? category, String? search})>(
  (ref, args) => ref.watch(databaseProvider).watchExercises(
        category: args.category,
        search: args.search,
      ),
);

final dbExerciseCountProvider = StreamProvider.autoDispose<int>(
  (ref) => ref.watch(databaseProvider).exerciseCount(),
);

final dbActiveWorkoutProvider = StreamProvider.autoDispose<Workout?>(
  (ref) => ref.watch(databaseProvider).watchActiveWorkout(),
);

/// The local (pre-auth) profile row — carries bodyweight for the Muscle
/// Grade strength component.
final profileProvider = StreamProvider<Profile?>(
  (ref) => (ref.watch(databaseProvider).profiles.select()
        ..where((p) => p.id.equals('local')))
      .watch()
      .map((rows) => rows.isEmpty ? null : rows.first),
);

/// Muscle catalog in display order (grade board + heat map).
final musclesProvider = StreamProvider<List<MuscleGroup>>((ref) {
  final db = ref.watch(databaseProvider);
  final q = db.muscleGroups.select()
    ..orderBy([(m) => OrderingTerm.asc(m.orderIndex)]);
  return q.watch();
});
