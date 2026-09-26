import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../application/analytics_providers.dart';
import '../domain/grade_engine.dart';
import 'charts.dart';

/// Per-muscle grade chips over the rolling 30-day window.
class GradeBoardCard extends ConsumerWidget {
  const GradeBoardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscles = ref.watch(musclesProvider).value;
    final window = ref.watch(muscleWindowProvider).value;
    final bodyweight = ref.watch(profileProvider).value?.bodyweightKg ?? 0;

    if (muscles == null || window == null) {
      return const ChartCard(
        title: 'Muscle Grades',
        subtitle: '30-day rolling · volume + strength + consistency',
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

    final now = DateTime.now();
    final cells = <({String name, GradeResult result})>[];
    for (final m in muscles) {
      if (m.id == 'cardio') continue; // no gradeable standard
      final w = window[m.id];
      final result = GradeEngine.grade(
        muscleId: m.id,
        volumeKg30d: w?.volumeKg ?? 0,
        bestE1RmKg: (w == null || w.bestE1Rm <= 0) ? null : w.bestE1Rm,
        bodyweightKg: bodyweight,
        daysTrained30d: w?.days.length ?? 0,
        targetSessions: GradeEngine.defaultTargetSessions,
        hoursSinceTrained: w?.hoursSinceTrained(now) ?? double.infinity,
      );
      cells.add((name: m.name, result: result));
    }

    return ChartCard(
      title: 'Muscle Grades',
      subtitle: '30-day rolling · volume + strength + consistency',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in cells)
            Container(
              key: Key('grade-${c.result.muscleId}'),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: context.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.result.grade,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gradeColor(c.result.grade),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        '${c.result.score.round()} pts',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
