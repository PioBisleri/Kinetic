import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/analytics_providers.dart';
import '../application/landmark_store.dart';
import '../domain/volume_landmarks.dart';
import '../../../core/database/database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/ledger/ledger.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import 'charts.dart';
import 'landmarks_sheets.dart';

/// Compact "volume landmarks" ledger: the six highest-priority muscles
/// against their MEV/MAV/MRV bands, with every muscle one tap away.
class VolumeLandmarksCard extends ConsumerWidget {
  const VolumeLandmarksCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscles = ref.watch(musclesProvider).value;
    final sets = ref.watch(periodSetsProvider).value;
    final overrides = ref.watch(landmarkOverridesProvider).value;
    final weeks = ref.watch(analyticsPeriodProvider);

    if (muscles == null || sets == null || overrides == null) {
      return const ChartCard(
        title: 'Volume landmarks',
        subtitle: 'hard sets per week',
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    final effective = LandmarkStore.effective(overrides);
    final rows = [
      for (final m in muscles)
        if (effective.containsKey(m.id)) m,
    ];
    final sorted = [...rows]..sort((a, b) => _priority(a, b, sets, effective));
    final preview = sorted.take(6).toList();

    return ChartCard(
      title: 'Volume landmarks',
      subtitle: weeks <= 0
          ? 'hard sets per week · all history'
          : 'hard sets per week · last $weeks weeks',
      onInfo: () => showLandmarksInfoSheet(context),
      infoKey: const Key('landmarks-info'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, m) in preview.indexed) ...[
            if (i > 0) Divider(height: 1, color: context.border),
            _LandmarkRow(
              muscleId: m.id,
              name: m.name,
              sets: sets[m.id] ?? 0,
              landmark: effective[m.id]!,
              edited: overrides.containsKey(m.id),
              onTap: () => showLandmarkEditSheet(
                context,
                muscleId: m.id,
                name: m.name,
                landmark: effective[m.id]!,
                edited: overrides.containsKey(m.id),
              ),
            ),
          ],
          Divider(height: 1, color: context.border),
          InkWell(
            key: const Key('landmarks-all'),
            onTap: () => showAppSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const _AllLandmarksSheet(),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Text(
                    'SEE ALL ${rows.length} MUSCLES',
                    style: AppType.meta.copyWith(color: context.accent),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: context.accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static int _priority(
    MuscleGroup a,
    MuscleGroup b,
    Map<String, int> sets,
    Map<String, Landmark> effective,
  ) {
    int rank(MuscleGroup m) =>
        switch (landmarkZone(sets[m.id] ?? 0, effective[m.id]!)) {
          LandmarkZone.aboveMrv => 0,
          LandmarkZone.belowMev => 1,
          LandmarkZone.aboveMav => 2,
          LandmarkZone.productive => 3,
        };
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    final bySets = (sets[b.id] ?? 0).compareTo(sets[a.id] ?? 0);
    if (bySets != 0) return bySets;
    return a.name.compareTo(b.name);
  }
}

class _AllLandmarksSheet extends ConsumerWidget {
  const _AllLandmarksSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscles = ref.watch(musclesProvider).value;
    final sets = ref.watch(periodSetsProvider).value;
    final overrides = ref.watch(landmarkOverridesProvider).value;
    final effective = overrides == null
        ? const <String, Landmark>{}
        : LandmarkStore.effective(overrides);
    final rows = [
      if (muscles != null)
        for (final m in muscles)
          if (effective.containsKey(m.id)) m,
    ];

    return FractionallySizedBox(
      key: const Key('landmarks-sheet'),
      heightFactor: 0.9,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'All landmarks',
                      style: AppType.h1.copyWith(color: context.textPrimary),
                    ),
                  ),
                  IconButton(
                    key: const Key('landmarks-close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            Rule(),
            if (sets == null)
              const Expanded(
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, m) in rows.indexed) ...[
                        if (i > 0) Divider(height: 1, color: context.border),
                        _LandmarkRow(
                          muscleId: m.id,
                          name: m.name,
                          sets: sets[m.id] ?? 0,
                          landmark: effective[m.id]!,
                          edited: overrides!.containsKey(m.id),
                          onTap: () => showLandmarkEditSheet(
                            context,
                            muscleId: m.id,
                            name: m.name,
                            landmark: effective[m.id]!,
                            edited: overrides.containsKey(m.id),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Color zoneColor(
  BuildContext context,
  LandmarkZone zone, {
  required bool bright,
}) => switch (zone) {
  LandmarkZone.belowMev => bright ? context.textSecondary : context.border,
  LandmarkZone.productive => bright ? context.accent : context.accentDim,
  LandmarkZone.aboveMav =>
    bright ? AppColors.heatWarm : AppColors.heatWarm.withValues(alpha: 0.45),
  LandmarkZone.aboveMrv =>
    bright ? AppColors.heatHot : AppColors.heatHot.withValues(alpha: 0.45),
};

class _LandmarkRow extends StatelessWidget {
  const _LandmarkRow({
    required this.muscleId,
    required this.name,
    required this.sets,
    required this.landmark,
    required this.edited,
    required this.onTap,
  });

  final String muscleId;
  final String name;
  final int sets;
  final Landmark landmark;
  final bool edited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final zone = landmarkZone(sets, landmark);
    final color = zoneColor(context, zone, bright: true);

    return InkWell(
      key: Key('landmark-$muscleId'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                if (edited) ...[
                  const SizedBox(width: 6),
                  Text(
                    'edited',
                    style: TextStyle(fontSize: 10, color: context.accent),
                  ),
                ],
                const Spacer(),
                Text(
                  '$sets',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  ' sets',
                  style: TextStyle(fontSize: 11, color: context.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _BandTrack(
              landmark: landmark,
              fraction: markerFraction(sets, landmark),
              color: color,
            ),
            const SizedBox(height: 5),
            Text(
              'MEV ${landmark.mev} · MAV ${landmark.mav} · '
              'MRV ${landmark.mrv}',
              style: TextStyle(fontSize: 10, color: context.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandTrack extends StatelessWidget {
  const _BandTrack({
    required this.landmark,
    required this.fraction,
    required this.color,
  });

  final Landmark landmark;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final (mevF, mavF, mrvF) = landmarkFractions(landmark);
    const dot = 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final left = (fraction * width - dot / 2).clamp(0.0, width - dot);
        return SizedBox(
          height: dot,
          child: Stack(
            children: [
              Positioned.fill(
                top: 2,
                bottom: 2,
                child: Row(
                  children: [
                    Expanded(
                      flex: (mevF * 200).round(),
                      child: ColoredBox(
                        color: zoneColor(
                          context,
                          LandmarkZone.belowMev,
                          bright: false,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((mavF - mevF) * 200).round(),
                      child: ColoredBox(
                        color: zoneColor(
                          context,
                          LandmarkZone.productive,
                          bright: false,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((mrvF - mavF) * 200).round(),
                      child: ColoredBox(
                        color: zoneColor(
                          context,
                          LandmarkZone.aboveMav,
                          bright: false,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((1 - mrvF) * 200).round(),
                      child: ColoredBox(
                        color: zoneColor(
                          context,
                          LandmarkZone.aboveMrv,
                          bright: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: left,
                top: 0,
                child: Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(color: context.surface, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
