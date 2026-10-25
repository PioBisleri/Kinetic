import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ledger/ledger.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import 'application/analytics_providers.dart';
import 'domain/analytics_math.dart';
import 'widgets/balance_card.dart';
import 'widgets/body_map.dart';
import 'widgets/charts.dart';
import 'widgets/grade_board.dart';
import 'widgets/landmarks_card.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeks = ref.watch(analyticsPeriodProvider);
    final unit = ref.watch(settingsProvider).unit;
    final stats = ref.watch(workoutStatsProvider(weeks)).value;
    final daily = ref.watch(dailyVolumeProvider(weeks)).value;
    final now = DateTime.now();

    return Scaffold(
      appBar: const TailBar(
        title: 'Analytics',
        meta: 'Volume · strength · balance',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.x5,
          AppSpace.x1,
          AppSpace.x5,
          AppSpace.x8,
        ),
        children: [
          const SectionHead(
            index: '00',
            title: 'Window',
            meta: 'rolling ledger',
          ),
          const SizedBox(height: AppSpace.x3),
          const PeriodChips(),
          const SizedBox(height: AppSpace.x4),
          if (stats == null || daily == null)
            const _LoadingCard()
          else ...[
            StatsRow(
              workoutCount: stats.count,
              streakWeeks: stats.streak,
              volumeKg: daily.fold(0.0, (a, r) => a + r.totalVolume),
              unit: unit,
            ),
            const SizedBox(height: AppSpace.x6),
            if (stats.count == 0)
              const _EmptyCard()
            else ...[
              const ChapterHead(
                index: '01',
                title: 'Training',
                meta: 'load · trend · consistency',
              ),
              const SizedBox(height: AppSpace.x4),
              ChartCard(
                title: 'Weekly volume',
                subtitle: 'total working volume per week',
                child: WeeklyVolumeChart(
                  points: bucketWeekly(
                    [
                      for (final r in daily)
                        (date: r.date, volumeKg: r.totalVolume),
                    ],
                    now: now,
                    weeks: weeks,
                  ),
                  unit: unit,
                ),
              ),
              const SizedBox(height: AppSpace.x4),
              StrengthCard(
                weeks: weeks,
                unit: unit,
                // "All" anchors the axis at the first logged day, not 1970.
                windowStart: chartStart(weeks, now, [
                  for (final r in daily) r.date,
                ]),
              ),
              const SizedBox(height: AppSpace.x4),
              const ConsistencyCard(),
              const SizedBox(height: AppSpace.x6),
              const ChapterHead(
                index: '02',
                title: 'Muscle',
                meta: 'dose · grade · recovery',
              ),
              const SizedBox(height: AppSpace.x4),
              const VolumeLandmarksCard(),
              const SizedBox(height: AppSpace.x4),
              const GradeBoardCard(),
              const SizedBox(height: AppSpace.x4),
              const BodyHeatMap(),
              const SizedBox(height: AppSpace.x6),
              const ChapterHead(
                index: '03',
                title: 'Balance',
                meta: 'agonist vs antagonist',
              ),
              const SizedBox(height: AppSpace.x4),
              const BalanceCard(),
            ],
          ],
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const LedgerPanel(
      child: SizedBox(
        height: 90,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return LedgerPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No data yet.',
            style: AppType.h2.copyWith(color: context.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Finish a workout from Home and the ledger starts filling in.',
            style: AppType.bodySm.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}
