import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_providers.dart';
import '../../core/ledger/ledger.dart';
import '../../core/theme/app_theme.dart';
import 'your_data_card.dart';

const _goalLabels = {
  'strength': 'Strength',
  'hypertrophy': 'Hypertrophy',
  'general': 'General fitness',
};

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const TailBar(title: 'Profile', meta: 'Identity · body'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.x5,
          AppSpace.x2,
          AppSpace.x5,
          AppSpace.x8,
        ),
        children: const [
          _ProfileHeader(),
          SizedBox(height: AppSpace.x6),
          YourDataCard(),
        ],
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final name = profile?.username?.trim();
    final goal = _goalLabels.containsKey(profile?.trainingGoal)
        ? _goalLabels[profile?.trainingGoal]
        : null;
    final initial = (name == null || name.isEmpty)
        ? null
        : name[0].toUpperCase();

    return LedgerPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.x4),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.accent,
                    border: Border.all(color: context.accent),
                  ),
                  child: Text(
                    initial ?? 'K',
                    style: AppType.h1.copyWith(
                      color: onAccent(context.accent),
                      fontSize: 26,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.h1.copyWith(color: context.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (goal ?? 'Offline-first training log').toUpperCase(),
                        style: AppType.metaSm.copyWith(
                          color: context.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Rule(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.x4,
              vertical: 10,
            ),
            child: Row(
              children: [
                Text(
                  'LOCAL RECORD',
                  style: AppType.metaSm.copyWith(color: context.textTertiary),
                ),
                const SizedBox(width: AppSpace.x3),
                Expanded(
                  child: Text(
                    'SETTINGS → DATA',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.metaSm.copyWith(color: context.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
