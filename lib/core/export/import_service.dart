import 'dart:convert';

import '../../features/analytics/application/rollup_service.dart';
import '../../features/analytics/domain/analytics_math.dart';
import '../database/database.dart';
import 'export_service.dart' show backupSerializer;

/// A validated backup, plus counts for the confirmation dialog.
/// Produced by [ImportService.parse]; the raw document rides along so the
/// caller can hand it straight to [ImportService.importJson].
class BackupPreview {
  const BackupPreview({
    required this.doc,
    required this.exportedAt,
    required this.exercises,
    required this.routines,
    required this.workouts,
  });

  final Map<String, dynamic> doc;
  final String? exportedAt; // ISO-8601, as written by the exporter
  final int exercises;
  final int routines;
  final int workouts;
}

/// What a completed import restored.
class ImportSummary {
  const ImportSummary({
    required this.exercises,
    required this.routines,
    required this.workouts,
    required this.sets,
    required this.profileRestored,
  });

  final int exercises;
  final int routines;
  final int workouts;
  final int sets;
  final bool profileRestored;
}

/// Restores a JSON backup — the exact document shape `buildBackupJson`
/// writes (JSON only; CSV stays export-only).
///
/// Replace-all semantics: the backup becomes the entire local dataset
/// inside one transaction, then the analytics rollups are rebuilt for
/// every day the restored sets touched — so Home/Analytics/heat map agree
/// with the restored history immediately. The muscle-group catalog is
/// never touched (it is bundled content, not user data).
class ImportService {
  ImportService(this._db);

  final AppDatabase _db;

  /// Newest backup format this build understands.
  static const currentFormat = 1;

  /// Validates [content] without writing anything. Throws
  /// [FormatException] with a message that is safe to show the user.
  static BackupPreview parse(String content) {
    Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      throw const FormatException('That file is not valid JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Not a Kinetic backup file.');
    }
    if (decoded['app'] != 'kinetic') {
      throw const FormatException('Not a Kinetic backup file.');
    }
    final format = decoded['format'];
    if (format is! int || format < 1) {
      throw const FormatException('Backup has an unrecognised format.');
    }
    if (format > currentFormat) {
      throw const FormatException(
        'This backup was made by a newer version of Kinetic.',
      );
    }
    for (final key in const ['exercises', 'routines', 'workouts']) {
      if (decoded[key] is! List) {
        throw FormatException('Backup is missing its $key section.');
      }
    }
    return BackupPreview(
      doc: decoded,
      exportedAt: decoded['exportedAt'] is String
          ? decoded['exportedAt'] as String
          : null,
      exercises: (decoded['exercises'] as List).length,
      routines: (decoded['routines'] as List).length,
      workouts: (decoded['workouts'] as List).length,
    );
  }

  /// Fills in fields added after a backup was written.
  ///
  /// Backups all share `format: 1` (the shape is additive), so a pre-v3
  /// file simply lacks the v3 keys — and drift's generated `fromJson`
  /// throws on a missing non-nullable int. Two cases:
  ///
  /// * routine entries: no `warmupSets` yet → derive the counts from the
  ///   v1/v2 `isWarmup` flag, and rewrite `restSeconds` (a placeholder no
  ///   UI could ever edit before Round 3) to [inheritRestSeconds];
  /// * exercises: `restSeconds` is nullable, so an absent key already
  ///   decodes to null = "inherit" and needs no patch.
  static Map<String, dynamic> _normalize(Map<String, dynamic> doc) {
    for (final routine in doc['routines'] as List) {
      final entries =
          (routine as Map<String, dynamic>)['entries'] as List? ?? const [];
      for (final entry in entries) {
        final e = entry as Map<String, dynamic>;
        if (e.containsKey('warmupSets')) continue; // already v3
        final total = (e['targetSets'] as num?)?.toInt() ?? 3;
        final wasWarmup = e['isWarmup'] == true;
        e['warmupSets'] = wasWarmup ? total : 0;
        e['dropSets'] = 0;
        e['failureSets'] = 0;
        e['restSeconds'] = inheritRestSeconds;
      }
    }
    return doc;
  }

  /// Replaces all local data with the backup's contents, then rebuilds
  /// the analytics rollups. Throws [FormatException] before touching the
  /// database if the document is invalid.
  Future<ImportSummary> importJson(String content) async {
    final preview = parse(content);
    final doc = _normalize(preview.doc);

    // ---- decode first: any problem throws before a single row is written
    final profile = _decode(() => doc['profile'] is Map<String, dynamic>
        ? Profile.fromJson(
            doc['profile'] as Map<String, dynamic>,
            serializer: backupSerializer,
          )
        : null);
    final exercises = _decode(() => [
          for (final j in doc['exercises'] as List)
            Exercise.fromJson(
              j as Map<String, dynamic>,
              serializer: backupSerializer,
            ),
        ]);
    final muscleMap = _decode(() => [
          for (final j in doc['exercises'] as List)
            for (final m in ((j as Map<String, dynamic>)['muscleMap']
                    as List? ??
                const []))
              ExerciseMuscleMapData.fromJson(
                m as Map<String, dynamic>,
                serializer: backupSerializer,
              ),
        ]);
    final routines = _decode(() => [
          for (final j in doc['routines'] as List)
            Routine.fromJson(
              j as Map<String, dynamic>,
              serializer: backupSerializer,
            ),
        ]);
    final slots = _decode(() => [
          for (final j in doc['routines'] as List)
            for (final e in ((j as Map<String, dynamic>)['entries']
                    as List? ??
                const []))
              RoutineExercise.fromJson(
                e as Map<String, dynamic>,
                serializer: backupSerializer,
              ),
        ]);
    final workouts = _decode(() => [
          for (final j in doc['workouts'] as List)
            Workout.fromJson(
              j as Map<String, dynamic>,
              serializer: backupSerializer,
            ),
        ]);
    final sets = _decode(() => [
          for (final j in doc['workouts'] as List)
            for (final s
                in ((j as Map<String, dynamic>)['sets'] as List? ?? const []))
              WorkoutSet.fromJson(
                s as Map<String, dynamic>,
                serializer: backupSerializer,
              ),
        ]);

    // ---- replace-all, parents before children (no FK constraints exist)
    await _db.transaction(() async {
      await _db.delete(_db.workoutSets).go();
      await _db.delete(_db.workouts).go();
      await _db.delete(_db.routineExercises).go();
      await _db.delete(_db.routines).go();
      await _db.delete(_db.exerciseHistory).go();
      await _db.delete(_db.muscleVolumeDaily).go();
      await _db.delete(_db.muscleGradeHistory).go();
      await _db.delete(_db.exerciseMuscleMap).go();
      await _db.delete(_db.exercises).go();

      for (final e in exercises) {
        await _db.into(_db.exercises).insertOnConflictUpdate(e.toCompanion(false));
      }
      for (final m in muscleMap) {
        await _db
            .into(_db.exerciseMuscleMap)
            .insertOnConflictUpdate(m.toCompanion(false));
      }
      for (final r in routines) {
        await _db.into(_db.routines).insertOnConflictUpdate(r.toCompanion(false));
      }
      for (final s in slots) {
        await _db
            .into(_db.routineExercises)
            .insertOnConflictUpdate(s.toCompanion(false));
      }
      for (final w in workouts) {
        await _db.into(_db.workouts).insertOnConflictUpdate(w.toCompanion(false));
      }
      for (final s in sets) {
        await _db
            .into(_db.workoutSets)
            .insertOnConflictUpdate(s.toCompanion(false));
      }
      if (profile != null) {
        await _db.into(_db.profiles).insertOnConflictUpdate(profile.toCompanion(false));
      }
    });

    // ---- rebuild rollups day-by-day (idempotent, see RollupService)
    final days = <DateTime>{
      for (final s in sets)
        if (s.isCompleted && s.loggedAt != null) dayOf(s.loggedAt!),
    };
    final rollups = RollupService(_db);
    for (final day in days) {
      await rollups.recomputeDay(day);
    }

    return ImportSummary(
      exercises: exercises.length,
      routines: routines.length,
      workouts: workouts.length,
      sets: sets.length,
      profileRestored: profile != null,
    );
  }

  /// Runs [run], converting any row-decoding failure into a user-safe
  /// [FormatException] (parse() already validated the document shell).
  static T _decode<T>(T Function() run) {
    try {
      return run();
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Backup contains invalid data.');
    }
  }
}
