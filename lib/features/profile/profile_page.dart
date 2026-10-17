import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import '../../core/database/database_providers.dart';
import '../../core/database/delete_service.dart';
import '../../core/export/export_service.dart';
import '../../core/export/import_service.dart';
import '../../core/navigation/shell_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_dialog.dart';
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
          const _ProfileHeader(),
          const SizedBox(height: 16),
          const YourDataCard(),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Privacy',
            icon: Icons.shield_outlined,
            children: [
              const ListTile(
                leading: Icon(Icons.lock_outline_rounded),
                title: Text('Fully private'),
                subtitle: Text(
                  'No friends, no followers, no feed. Your data stays on this '
                  'device and your own encrypted backup.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Data',
            icon: Icons.folder_copy_outlined,
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
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Danger zone',
            icon: Icons.warning_amber_rounded,
            iconColor: context.danger,
            children: [
              ListTile(
                key: const Key('delete-history'),
                leading: Icon(Icons.delete_sweep_outlined, color: context.danger),
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
                leading: Icon(Icons.delete_sweep_outlined, color: context.danger),
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
                leading: Icon(Icons.delete_sweep_outlined, color: context.danger),
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
                leading: Icon(Icons.delete_forever_outlined, color: context.danger),
                title: const Text('Delete all data'),
                subtitle: const Text('History, routines, custom exercises — '
                    'type DELETE to confirm'),
                onTap: () => _deleteAll(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'About',
            icon: Icons.info_outline_rounded,
            children: [
              ListTile(
                leading: Icon(Icons.fitness_center_rounded,
                    color: context.textSecondary),
                title: const Text('Kinetic'),
                subtitle: const Text('Offline-first training log'),
              ),
            ],
          ),
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
      // Share sheet dismissed / temp write failed — tell the user instead
      // of failing silently (Round 9 F4).
      debugPrint('Export failed: $e');
      if (ref.context.mounted) {
        _snack(ref.context, 'Export failed — try again or free some space.');
      }
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

      final ok = await confirmAction(
        context,
        title: 'Import backup?',
        message: 'This replaces ALL current data with the backup from '
            '${_fmtDate(preview.exportedAt)}:\n\n'
            '${preview.exercises} exercises · '
            '${preview.routines} routines · '
            '${preview.workouts} workouts\n\n'
            'This cannot be undone — export a backup first if unsure.',
        confirmLabel: 'Import',
        danger: true,
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
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
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

const _goalLabels = {
  'strength': 'Strength',
  'hypertrophy': 'Hypertrophy',
  'general': 'General fitness',
};

/// Hero header (Round 9.2): avatar disc with the name's initial, the
/// display name and the training goal — one glance instead of a form.
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final name = profile?.username?.trim();
    final goal = _goalLabels.containsKey(profile?.trainingGoal)
        ? _goalLabels[profile?.trainingGoal]
        : null;
    final initial =
        (name == null || name.isEmpty) ? null : name[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.accent,
            ),
            child: Text(
              initial ?? 'K',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: onAccent(context.accent),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (name == null || name.isEmpty) ? 'Your profile' : name,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: context.textPrimary,
                  ),
                ),
                if (goal != null)
                  Text(goal, style: TextStyle(fontSize: 13, color: context.textSecondary))
                else
                  Text(
                    'Offline-first training log',
                    style: TextStyle(fontSize: 13, color: context.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
