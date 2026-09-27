import 'package:drift/drift.dart';

import '../../../core/database/database.dart';
import '../domain/volume_landmarks.dart';

/// Reads and writes for the volume-landmark *overrides*. The numbers
/// themselves (defaults, zones, band math) live in the pure domain file;
/// this class only knows how to persist edits over them.
class LandmarkStore {
  LandmarkStore(this._db);

  final AppDatabase _db;

  /// Effective landmarks for every defaulted muscle: the override row
  /// where the user edited, the curated default everywhere else.
  static Map<String, Landmark> effective(
    Map<String, VolumeLandmark> overrides,
  ) =>
      {
        for (final e in landmarkDefaults.entries)
          e.key: _fromRow(overrides[e.key]) ?? e.value,
      };

  static Landmark? _fromRow(VolumeLandmark? row) => row == null
      ? null
      : Landmark(mev: row.mevSets, mav: row.mavSets, mrv: row.mrvSets);

  /// Persist an edit (upsert). Callers validate with [Landmark.isValid].
  Future<void> save(String muscleId, Landmark lm) async {
    await _db.into(_db.volumeLandmarks).insertOnConflictUpdate(
          VolumeLandmarksCompanion.insert(
            muscleId: muscleId,
            mevSets: lm.mev,
            mavSets: lm.mav,
            mrvSets: lm.mrv,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  /// Drop the override so the muscle falls back to its default.
  Future<void> reset(String muscleId) async {
    await (_db.volumeLandmarks.delete()
          ..where((v) => v.muscleId.equals(muscleId)))
        .go();
  }
}
