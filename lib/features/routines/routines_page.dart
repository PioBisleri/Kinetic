import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ledger/ledger.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_dialog.dart';
import '../workout/application/workout_session_notifier.dart';
import 'application/routine_providers.dart';

/// The Routines tab: a ledger index of saved plans, one-tap start, and the
/// entry points to the builder and exercise library.
class RoutinesPage extends ConsumerWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routinesProvider);

    return Scaffold(
      appBar: TailBar(
        title: 'Routines',
        meta: 'TRAINING INDEX',
        actions: [
          TextButton(
            key: const Key('open-library'),
            onPressed: () => context.push('/library'),
            style: TextButton.styleFrom(
              foregroundColor: context.textSecondary,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x3),
              textStyle: AppType.meta.copyWith(letterSpacing: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('LIBRARY'),
                const SizedBox(width: 6),
                LedgerGlyph(
                  LedgerGlyphType.chevronRight,
                  size: 12,
                  color: context.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
      body: routines.when(
        loading: () => const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cards) {
          final totalSets = cards.fold<int>(
            0,
            (sum, card) => sum + card.targetSetCount,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.x5,
              AppSpace.x1,
              AppSpace.x5,
              AppSpace.x8,
            ),
            children: [
              _PlanIndex(
                count: cards.length,
                totalSets: totalSets,
                onNew: () => context.push('/routines/new'),
              ),
              const SizedBox(height: AppSpace.x6),
              SectionHead(
                index: '01',
                title: 'Saved plans',
                meta: cards.isEmpty
                    ? 'NONE YET'
                    : '${cards.length} TOTAL · TAP TO EDIT',
              ),
              const SizedBox(height: AppSpace.x3),
              if (cards.isEmpty)
                const _EmptyPlans()
              else
                for (var i = 0; i < cards.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.x3),
                    child: _RoutinePanel(
                      index: i,
                      card: cards[i],
                      onStart: () =>
                          _startRoutine(context, ref, cards[i].routine.id),
                      onEdit: () =>
                          context.push('/routines/${cards[i].routine.id}'),
                    ),
                  ),
              const SizedBox(height: AppSpace.x2),
              Text(
                'Plans stay local. Start one from here or pick it from Home.',
                style: AppType.metaSm.copyWith(color: context.textTertiary),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startRoutine(
    BuildContext context,
    WidgetRef ref,
    String routineId,
  ) async {
    final session = ref.read(workoutSessionProvider).value;
    if (session != null) {
      showSnack(context, 'Finish your current workout first.');
      return;
    }
    await ref
        .read(workoutSessionProvider.notifier)
        .startWorkout(routineId: routineId);
    if (context.mounted) context.push('/workout');
  }
}

class _PlanIndex extends StatelessWidget {
  const _PlanIndex({
    required this.count,
    required this.totalSets,
    required this.onNew,
  });

  final int count;
  final int totalSets;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final countLabel = count.toString().padLeft(2, '0');
    final setsLabel = totalSets.toString().padLeft(2, '0');

    return LedgerPanel(
      accentTop: true,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, color: context.accent),
              const SizedBox(width: 8),
              Text(
                'PLAN INDEX',
                style: AppType.meta.copyWith(color: context.accent),
              ),
              const Spacer(),
              Text(
                'LOCAL / PRIVATE',
                style: AppType.metaSm.copyWith(color: context.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.x4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                countLabel,
                style: AppType.dataHero.copyWith(
                  color: context.textPrimary,
                  height: 0.9,
                ),
              ),
              const SizedBox(width: AppSpace.x3),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SAVED PLANS',
                      style: AppType.meta.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$setsLabel PLANNED SETS',
                      style: AppType.metaSm.copyWith(
                        color: context.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.x3),
          Text(
            'Build a reusable plan once; start it in one tap.',
            style: AppType.bodySm.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: AppSpace.x4),
          PushKey(
            key: const Key('new-routine'),
            label: 'New Routine',
            height: 48,
            onPressed: onNew,
            icon: LedgerGlyph(
              LedgerGlyphType.plus,
              size: 15,
              strokeWidth: 2,
              color: onAccent(context.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  const _EmptyPlans();

  @override
  Widget build(BuildContext context) {
    return LedgerPanel(
      grid: true,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('00', style: AppType.meta.copyWith(color: context.textTertiary)),
          const SizedBox(height: AppSpace.x2),
          Text(
            'No routines yet',
            style: AppType.h2.copyWith(color: context.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Build a reusable plan, then start it in one tap. '
            'Nothing leaves this device.',
            style: AppType.bodySm.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RoutinePanel extends StatelessWidget {
  const _RoutinePanel({
    required this.index,
    required this.card,
    required this.onStart,
    required this.onEdit,
  });

  final int index;
  final RoutineCard card;
  final VoidCallback onStart;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final routineNumber = (index + 1).toString().padLeft(2, '0');

    return LedgerPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onEdit,
              splashColor: context.accent.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    Text(
                      routineNumber,
                      style: AppType.meta.copyWith(color: context.textTertiary),
                    ),
                    const SizedBox(width: AppSpace.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.routine.name,
                            style: AppType.h2.copyWith(
                              color: context.textPrimary,
                              height: 1.05,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${card.exerciseCount} exercises · '
                            '${card.targetSetCount} sets',
                            style: AppType.bodySm.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    LedgerGlyph(
                      LedgerGlyphType.chevronRight,
                      size: 14,
                      color: context.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Rule(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
            child: Row(
              children: [
                Text(
                  'READY',
                  style: AppType.metaSm.copyWith(color: context.textTertiary),
                ),
                const Spacer(),
                TextButton.icon(
                  key: Key('start-routine-${card.routine.id}'),
                  onPressed: onStart,
                  style: TextButton.styleFrom(
                    foregroundColor: context.accent,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: AppType.meta.copyWith(letterSpacing: 1),
                  ),
                  icon: LedgerGlyph(
                    LedgerGlyphType.play,
                    size: 12,
                    color: context.accent,
                  ),
                  label: const Text('START'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
