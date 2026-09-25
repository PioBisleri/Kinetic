import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings.dart';
import '../../core/theme/app_theme.dart';
import 'application/analytics_providers.dart';
import 'domain/analytics_math.dart';
import 'widgets/balance_card.dart';
import 'widgets/body_map.dart';
import 'widgets/charts.dart';
import 'widgets/grade_board.dart';

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
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PeriodChips(),
          const SizedBox(height: 12),
          if (stats == null || daily == null)
            const _LoadingCard()
          else ...[
            StatsRow(
              workoutCount: stats.count,
              streakWeeks: stats.streak,
              volumeKg: daily.fold(0.0, (a, r) => a + r.totalVolume),
              unit: unit,
            ),
            const SizedBox(height: 16),
            if (stats.count == 0)
              const _EmptyCard()
            else ...[
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
              const SizedBox(height: 16),
              StrengthCard(
                weeks: weeks,
                unit: unit,
                windowStart: periodStart(weeks, now),
              ),
              const SizedBox(height: 16),
              const ConsistencyCard(),
              const SizedBox(height: 16),
              const GradeBoardCard(),
              const SizedBox(height: 16),
              const BodyHeatMap(),
              const SizedBox(height: 16),
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
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No finished workouts yet — start one from Home and your '
            'trends appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: context.textSecondary),
          ),
        ),
      ),
    );
  }
}
