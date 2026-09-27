import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/database/delete_service.dart';
import '../../core/export/export_service.dart';
import '../../core/export/import_service.dart';
import '../../core/navigation/shell_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_card.dart';
import '../workout/application/workout_session_notifier.dart';
import 'your_data_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: const DrawerMenuButton(),
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const YourDataCard(),
          const SizedBox(height: 16),
          SectionCard(title: 'Privacy', children: [
            const ListTile(
              leading: Icon(Icons.lock_outline_rounded),
              title: Text('Fully private'),
              subtitle: Text(
                'No friends, no followers, no feed. Your data stays on this '
                'device and your own encrypted backup.',
              ),
            ),
          ]),
          const SizedBox(height: 16),
          SectionCard(title: 'Data', children: [
            ListTile(
              key: const Key('export-json'),
              leading: const Icon(Icons.data_object_rounded),
              title: const Text('Export JSON backup'),
              subtitle: const Text('Profile, routines and full history'),
              onTap: () => _export(ref, ExportKind.json),
            ),
            ListTile(
              key: const Key('export-csv'),
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Export CSV'),
              subtitle: const Text('Every set — for spreadsheets (weights in kg)'),
              onTap: () => _export(ref, ExportKind.csv),
            ),
            ListTile(
              key: const Key('import-json'),
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Import JSON backup'),
              subtitle: const Text('Replaces all current data'),
              onTap: () => _import(context, ref),
            ),
          ]),
          const SizedBox(height: 16),
          SectionCard(title: 'Danger zone', children: [
            ListTile(
              key: const Key('delete-history'),
              leading: const Icon(Icons.delete_sweep_outlined,
                  color: AppColors.heatHot),
              title: const Text('Delete workout history'),
              subtitle:
                  const Text('Finished workouts and their analytics (routines stay)'),
              onTap: () => _confirmDelete(
                context,
                ref,
                title: 'Delete workout history?',
                message: 'Deletes every finished workout and its sets. '
                    'Charts, streaks and volume recompute immediately. '
                    'Routines and exercises are kept.',
                doneMessage: 'Workout history deleted',
                run: (service) => service.deleteWorkoutHistory(),
              ),
            ),
            ListTile(
              key: const Key('delete-routines'),
              leading: const Icon(Icons.delete_sweep_outlined,
                  color: AppColors.heatHot),
              title: const Text('Delete routines'),
              subtitle: const Text('Every saved routine and its plan'),
              onTap: () => _confirmDelete(
                context,
                ref,
                title: 'Delete routines?',
                message: 'Deletes all routines and their planned exercises. '
                    'Workout history and the exercise library are kept.',
                doneMessage: 'Routines deleted',
                run: (service) => service.deleteRoutines(),
              ),
            ),
            ListTile(
              key: const Key('delete-custom-exercises'),
              leading: const Icon(Icons.delete_sweep_outlined,
                  color: AppColors.heatHot),
              title: const Text('Delete custom exercises'),
              subtitle:
                  const Text('Your created exercises and their logged sets'),
              onTap: () => _confirmDelete(
                context,
                ref,
                title: 'Delete custom exercises?',
                message: 'Deletes every exercise you created, together with '
                    'its sets, history and routine slots. The seeded '
                    'exercise library is kept.',
                doneMessage: 'Custom exercises deleted',
                run: (service) => service.deleteCustomExercises(),
              ),
            ),
            ListTile(
              key: const Key('delete-all'),
              leading: const Icon(Icons.delete_forever_outlined,
                  color: AppColors.heatHot),
              title: const Text('Delete all data'),
              subtitle: const Text('History, routines, custom exercises — '
                  'type DELETE to confirm'),
              onTap: () => _deleteAll(context, ref),
            ),
          ]),
          const SizedBox(height: 16),
          SectionCard(title: 'About', children: [
            ListTile(
              leading: Icon(Icons.info_outline,
                  color: context.textSecondary),
              title: const Text('Kinetic'),
              subtitle: const Text('Version 0.1.2 · offline-first'),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _export(WidgetRef ref, ExportKind kind) async {
    try {
      final service = ExportService(ref.read(databaseProvider));
      if (kind == ExportKind.json) {
        await service.shareJsonBackup();
      } else {
        await service.shareSetsCsv();
      }
    } catch (e) {
      // Share sheet dismissed / temp write failed — the export is best-effort.
      debugPrint('Export failed: $e');
    }
  }

  /// Picks a JSON backup, previews what it replaces, then restores it.
  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (files.isEmpty) return;
      final content =
          utf8.decode(await files.single.readAsBytes(), allowMalformed: true);

      // Validate BEFORE the confirmation dialog — a bad file never prompts.
      final preview = ImportService.parse(content);
      if (!context.mounted) return;

      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import backup?'),
          content: Text(
            'This replaces ALL current data with the backup from '
            '${_fmtDate(preview.exportedAt)}:\n\n'
            '${preview.exercises} exercises · '
            '${preview.routines} routines · '
            '${preview.workouts} workouts\n\n'
            'This cannot be undone — export a backup first if unsure.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.heatHot,
                minimumSize: const Size(0, 44),
              ),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;

      final summary =
          await ImportService(ref.read(databaseProvider)).importJson(content);
      ref.invalidate(workoutSessionProvider);
      if (context.mounted) {
        _snack(
          context,
          'Imported ${summary.workouts} workouts · '
          '${summary.routines} routines',
        );
      }
    } on FormatException catch (e) {
      if (context.mounted) _snack(context, e.message);
    } catch (e) {
      debugPrint('Import failed: $e');
      if (context.mounted) {
        _snack(context, 'Import failed — could not read that file.');
      }
    }
  }

  /// One confirmation dialog for the three scoped deletions.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required String doneMessage,
    required Future<void> Function(DeleteService service) run,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.heatHot,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await run(DeleteService(ref.read(databaseProvider)));
    ref.invalidate(workoutSessionProvider);
    if (context.mounted) _snack(context, doneMessage);
  }

  /// The nuclear option — requires typing DELETE.
  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => const _TypeToDeleteDialog(),
    );
    if (ok != true || !context.mounted) return;
    await DeleteService(ref.read(databaseProvider)).deleteAllData();
    ref.invalidate(workoutSessionProvider);
    if (context.mounted) _snack(context, 'All data deleted');
  }

  String _fmtDate(String? iso) {
    final t = iso == null ? null : DateTime.tryParse(iso);
    return t == null
        ? 'an unknown date'
        : DateFormat('MMM d, yyyy').format(t.toLocal());
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Wipe-everything confirmation: the destructive button only enables once
/// the user types DELETE (case-insensitive).
class _TypeToDeleteDialog extends StatefulWidget {
  const _TypeToDeleteDialog();

  @override
  State<_TypeToDeleteDialog> createState() => _TypeToDeleteDialogState();
}

class _TypeToDeleteDialogState extends State<_TypeToDeleteDialog> {
  bool _typed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete all data?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deletes every workout, routine, custom exercise and your '
            'profile, then restores the blank exercise catalog. '
            'This cannot be undone.',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('confirm-delete-all'),
            decoration: const InputDecoration(
              labelText: 'Type DELETE to confirm',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(
              () => _typed = v.trim().toUpperCase() == 'DELETE',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _typed ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.heatHot,
            minimumSize: const Size(0, 44),
          ),
          child: const Text('Delete everything'),
        ),
      ],
    );
  }
}

enum ExportKind { json, csv }
