import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/database/delete_service.dart';
import '../../core/export/export_service.dart';
import '../../core/export/import_service.dart';
import '../../core/ledger/ledger.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_dialog.dart';
import '../workout/application/workout_session_notifier.dart';

/// Data, privacy, about and the destructive actions — moved here from
/// Profile in Round 12 so Profile stays about identity and body.
class DataPrivacyAboutSections extends ConsumerWidget {
  const DataPrivacyAboutSections({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LedgerGroup(
          title: 'Data',
          meta: 'backup · import',
          children: [
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
              subtitle: const Text(
                'Every set — for spreadsheets (weights in kg)',
              ),
              onTap: () => _export(ref, ExportKind.csv),
            ),
            ListTile(
              key: const Key('import-json'),
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Import JSON backup'),
              subtitle: const Text('Replaces all current data'),
              onTap: () => _import(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const LedgerGroup(
          title: 'Privacy',
          meta: 'on-device',
          children: [
            ListTile(
              leading: Icon(Icons.lock_outline_rounded),
              title: Text('Fully private'),
              subtitle: Text(
                'No friends, no followers, no feed. Your data stays on this '
                'device and your own encrypted backup.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const LedgerGroup(
          title: 'About',
          meta: 'build 0.2.0',
          children: [
            ListTile(
              leading: Icon(Icons.fitness_center_rounded),
              title: Text('Kinetic'),
              subtitle: Text('Offline-first training log'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LedgerGroup(
          title: 'Danger zone',
          meta: 'irreversible',
          children: [
            ListTile(
              key: const Key('delete-history'),
              leading: Icon(Icons.delete_sweep_outlined, color: context.danger),
              title: const Text('Delete workout history'),
              subtitle: const Text(
                'Finished workouts and their analytics (routines stay)',
              ),
              onTap: () => _confirmDelete(
                context,
                ref,
                title: 'Delete workout history?',
                message:
                    'Deletes every finished workout and its sets. '
                    'Charts, streaks and volume recompute immediately. '
                    'Routines and exercises are kept.',
                doneMessage: 'Workout history deleted',
                run: (service) => service.deleteWorkoutHistory(),
              ),
            ),
            ListTile(
              key: const Key('delete-routines'),
              leading: Icon(Icons.delete_sweep_outlined, color: context.danger),
              title: const Text('Delete routines'),
              subtitle: const Text('Every saved routine and its plan'),
              onTap: () => _confirmDelete(
                context,
                ref,
                title: 'Delete routines?',
                message:
                    'Deletes all routines and their planned exercises. '
                    'Workout history and the exercise library are kept.',
                doneMessage: 'Routines deleted',
                run: (service) => service.deleteRoutines(),
              ),
            ),
            ListTile(
              key: const Key('delete-custom-exercises'),
              leading: Icon(Icons.delete_sweep_outlined, color: context.danger),
              title: const Text('Delete custom exercises'),
              subtitle: const Text(
                'Your created exercises and their logged sets',
              ),
              onTap: () => _confirmDelete(
                context,
                ref,
                title: 'Delete custom exercises?',
                message:
                    'Deletes every exercise you created, together with '
                    'its sets, history and routine slots. The seeded '
                    'exercise library is kept.',
                doneMessage: 'Custom exercises deleted',
                run: (service) => service.deleteCustomExercises(),
              ),
            ),
            ListTile(
              key: const Key('delete-all'),
              leading: Icon(
                Icons.delete_forever_outlined,
                color: context.danger,
              ),
              title: const Text('Delete all data'),
              subtitle: const Text(
                'History, routines, custom exercises — '
                'type DELETE to confirm',
              ),
              onTap: () => _deleteAll(context, ref),
            ),
          ],
        ),
      ],
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
      debugPrint('Export failed: $e');
      if (ref.context.mounted) {
        _snack(ref.context, 'Export failed — try again or free some space.');
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (files.isEmpty) return;
      final content = utf8.decode(
        await files.single.readAsBytes(),
        allowMalformed: true,
      );

      final preview = ImportService.parse(content);
      if (!context.mounted) return;

      final ok = await confirmAction(
        context,
        title: 'Import backup?',
        message:
            'This replaces ALL current data with the backup from '
            '${_fmtDate(preview.exportedAt)}:\n\n'
            '${preview.exercises} exercises · '
            '${preview.routines} routines · '
            '${preview.workouts} workouts\n\n'
            'This cannot be undone — export a backup first if unsure.',
        confirmLabel: 'Import',
        danger: true,
      );
      if (ok != true || !context.mounted) return;

      final summary = await ImportService(ref.read(databaseProvider))
          .importJson(content);
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

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required String doneMessage,
    required Future<void> Function(DeleteService service) run,
  }) async {
    final ok = await confirmAction(
      context,
      title: title,
      message: message,
      confirmLabel: 'Delete',
      danger: true,
    );
    if (ok != true || !context.mounted) return;
    await run(DeleteService(ref.read(databaseProvider)));
    ref.invalidate(workoutSessionProvider);
    if (context.mounted) _snack(context, doneMessage);
  }

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
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

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
            onChanged: (v) =>
                setState(() => _typed = v.trim().toUpperCase() == 'DELETE'),
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
