import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database.dart';

/// Backup files are for humans: ISO-8601 strings instead of drift's default
/// unix-epoch millis.
const ValueSerializer backupSerializer =
    ValueSerializer.defaults(serializeDateTimeValuesAsString: true);

/// Pure JSON backup builder — full snapshot of user-owned data, nested by
/// parent (muscle map under exercise, slots under routine, sets under
/// workout). No file I/O, so it stays testable.
String buildBackupJson({
  required DateTime exportedAt,
  Profile? profile,
  required List<Exercise> exercises,
  required List<ExerciseMuscleMapData> muscleMap,
  required List<Routine> routines,
  required List<RoutineExercise> routineExercises,
  required List<Workout> workouts,
  required List<WorkoutSet> sets,
}) {
  final mapByExercise = <String, List<ExerciseMuscleMapData>>{};
  for (final m in muscleMap) {
    (mapByExercise[m.exerciseId] ??= []).add(m);
  }
  final slotsByRoutine = <String, List<RoutineExercise>>{};
  for (final e in routineExercises) {
    (slotsByRoutine[e.routineId] ??= []).add(e);
  }
  final setsByWorkout = <String, List<WorkoutSet>>{};
  for (final s in sets) {
    (setsByWorkout[s.workoutId] ??= []).add(s);
  }

  final doc = <String, dynamic>{
    'app': 'kinetic',
    'format': 1,
    'exportedAt': exportedAt.toIso8601String(),
    if (profile != null)
      'profile': profile.toJson(serializer: backupSerializer),
    'exercises': [
      for (final e in exercises)
        <String, dynamic>{
          ...e.toJson(serializer: backupSerializer),
          'muscleMap': [
            for (final m in mapByExercise[e.id] ?? const [])
              m.toJson(serializer: backupSerializer),
          ],
        },
    ],
    'routines': [
      for (final r in routines)
        <String, dynamic>{
          ...r.toJson(serializer: backupSerializer),
          'entries': [
            for (final e in slotsByRoutine[r.id] ?? const [])
              e.toJson(serializer: backupSerializer),
          ],
        },
    ],
    'workouts': [
      for (final w in workouts)
        <String, dynamic>{
          ...w.toJson(serializer: backupSerializer),
          'sets': [
            for (final s in setsByWorkout[w.id] ?? const [])
              s.toJson(serializer: backupSerializer),
          ],
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(doc);
}

/// Pure CSV builder — one row per set, oldest first (caller sorts).
/// `weight_kg` is always kilograms regardless of the display unit; [sets]
/// should include completed and planned rows alike (`completed` column).
String buildSetsCsv(
  List<WorkoutSet> sets,
  Map<String, String> exerciseNames,
) {
  final buf = StringBuffer()
    ..writeln(
      'date,logged_at,workout_id,exercise,exercise_id,set_type,weight_kg,'
      'reps,rpe,distance_m,duration_sec,heart_rate,completed,notes',
    );
  for (final s in sets) {
    final logged = s.loggedAt;
    final date = logged == null
        ? ''
        : '${logged.year}-'
            '${logged.month.toString().padLeft(2, '0')}-'
            '${logged.day.toString().padLeft(2, '0')}';
    buf.writeln(<String>[
      date,
      logged?.toIso8601String() ?? '',
      s.workoutId,
      _csvCell(exerciseNames[s.exerciseId] ?? s.exerciseId),
      s.exerciseId,
      s.setType,
      _cell(s.weightKg),
      _cell(s.reps),
      _cell(s.rpe),
      _cell(s.distanceM),
      _cell(s.durationSec),
      _cell(s.heartRate),
      s.isCompleted.toString(),
      _csvCell(s.notes ?? ''),
    ].join(','));
  }
  return buf.toString();
}

String _cell(Object? value) => value?.toString() ?? '';

String _csvCell(String value) {
  final needsQuotes = value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r');
  return needsQuotes ? '"${value.replaceAll('"', '""')}"' : value;
}

/// Gathers local rows and shares JSON/CSV exports through the OS share
/// sheet. Files go to the temp dir (they are ephemeral by design).
class ExportService {
  ExportService(this._db);

  final AppDatabase _db;

  Future<void> shareJsonBackup() async {
    await _share(await buildJson(), 'Kinetic backup (JSON)', 'json');
  }

  Future<void> shareSetsCsv() async {
    await _share(await _buildCsv(), 'Kinetic sets (CSV)', 'csv');
  }

  /// Builds the backup document (public so import round-trip tests can
  /// exercise the exact bytes a user would restore).
  Future<String> buildJson() async {
    final profile = await (_db.profiles.select()
          ..where((p) => p.id.equals('local')))
        .getSingleOrNull();
    final allExercises = await _db.exercises.select().get();
    final muscleMap = await _db.exerciseMuscleMap.select().get();
    final routines = await (_db.routines.select()
          ..where((r) => r.deletedAt.isNull()))
        .get();
    final workouts = await _db.workouts.select().get();

    final routineIds = {for (final r in routines) r.id};
    final workoutIds = {for (final w in workouts) w.id};
    final allSlots = await _db.routineExercises.select().get();
    final allSets = await _db.workoutSets.select().get();

    return buildBackupJson(
      exportedAt: DateTime.now(),
      profile: profile,
      exercises: [for (final e in allExercises) if (e.deletedAt == null) e],
      muscleMap: muscleMap,
      routines: routines,
      routineExercises: [
        for (final e in allSlots)
          if (routineIds.contains(e.routineId) && e.deletedAt == null) e,
      ],
      workouts: workouts,
      sets: [for (final s in allSets) if (workoutIds.contains(s.workoutId)) s],
    );
  }

  Future<String> _buildCsv() async {
    final exercises = await _db.exercises.select().get();
    final sets = await _db.workoutSets.select().get();
    final sorted = [...sets]..sort((a, b) {
        final at = a.loggedAt;
        final bt = b.loggedAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return at.compareTo(bt);
      });
    return buildSetsCsv(sorted, {
      for (final e in exercises) e.id: e.name,
    });
  }

  Future<void> _share(String content, String title, String ext) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/kinetic_export_${_stamp(DateTime.now())}.$ext');
    await file.writeAsString(content, flush: true);
    await SharePlus.instance.share(ShareParams(
      title: title,
      files: [XFile(file.path, mimeType: 'application/$ext')],
    ));
  }

  String _stamp(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}_'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }
}
