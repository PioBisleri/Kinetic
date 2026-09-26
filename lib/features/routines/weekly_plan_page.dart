import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/database/database_providers.dart';
import '../../core/theme/app_theme.dart';
import 'application/routine_providers.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// The weekly plan: seven days, one routine each, tap to reassign or
/// clear. Purely a planning surface — it schedules no reminders.
class WeeklyPlanPage extends ConsumerWidget {
  const WeeklyPlanPage({super.key});

  Future<void> _assign(WidgetRef ref, {required int day, String? routineId}) {
    final db = ref.read(databaseProvider);
    // Upsert by weekday PK; a fresh updatedAt (and a replaced row) keep
    // the sync outbox dirty for later rounds.
    return db.weeklyPlans.insertOnConflictUpdate(
      WeeklyPlansCompanion.insert(
        weekday: Value(day),
        routineId: Value(routineId),
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _openPicker(
      BuildContext context, WidgetRef ref, int day, String? currentId) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      builder: (_) => Consumer(
        builder: (sheetContext, ref, _) {
          final cards = ref.watch(routinesProvider);
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    _dayNames[day - 1],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: sheetContext.textTertiary,
                    ),
                  ),
                ),
                for (final card in cards.value ?? const <RoutineCard>[])
                  ListTile(
                    key: Key('plan-assign-${card.routine.id}'),
                    title: Text(card.routine.name),
                    trailing: card.routine.id == currentId
                        ? Icon(Icons.check, size: 20,
                            color: sheetContext.textSecondary)
                        : null,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _assign(ref, day: day, routineId: card.routine.id);
                    },
                  ),
                if ((cards.value ?? const <RoutineCard>[]).isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      'No routines yet — create one from the Routines tab.',
                      style: TextStyle(
                          fontSize: 13, color: sheetContext.textTertiary),
                    ),
                  ),
                if (currentId != null)
                  ListTile(
                    key: const Key('plan-clear'),
                    title: const Text('Rest day'),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _assign(ref, day: day, routineId: null);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(weeklyPlanProvider);
    final routines = ref.watch(routinesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly plan')),
      body: plan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rows) {
          final byDay = {for (final r in rows) r.weekday: r.routineId};
          final routineName = {
            for (final c in routines.value ?? const <RoutineCard>[])
              c.routine.id: c.routine.name,
          };
          final loaded = routines.value != null;

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Tap a day to plan a routine. Kinetic never sends '
                  'schedule reminders.',
                  style: TextStyle(
                      fontSize: 12, color: context.textTertiary),
                ),
              ),
              for (var i = 0; i < 7; i++) ...[
                Builder(
                  builder: (context) {
                    final day = i + 1;
                    final routineId = byDay[day];
                    final name = routineName[routineId];
                    final String title;
                    if (routineId == null) {
                      title = 'Rest day';
                    } else {
                      title = name ??
                          (loaded ? 'Routine deleted' : '…');
                    }
                    final assigned = routineId != null;
                    return ListTile(
                      key: Key('plan-day-$day'),
                      leading: SizedBox(
                        width: 44,
                        child: Text(
                          _dayNames[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight:
                              assigned ? FontWeight.w600 : FontWeight.w400,
                          color: assigned
                              ? context.textPrimary
                              : context.textTertiary,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: context.textTertiary,
                      ),
                      onTap: () =>
                          _openPicker(context, ref, day, routineId),
                    );
                  },
                ),
                if (i < 6) const Divider(height: 1),
              ],
            ],
          );
        },
      ),
    );
  }
}
