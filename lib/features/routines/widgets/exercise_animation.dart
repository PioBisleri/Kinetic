import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_theme.dart';
import '../application/animation_resolver.dart';

/// Renders an exercise's animation: Tier-0 bundled Lottie, cached Tier-1
/// file, or a styled placeholder (none / offline).
///
/// The Lottie player starts its repeat ticker immediately, so widget tests
/// that mount this must advance time with bounded pumps instead of
/// `pumpAndSettle`.
class ExerciseAnimation extends ConsumerWidget {
  const ExerciseAnimation({
    super.key,
    required this.animationKind,
    required this.animationRef,
    this.height = 220,
  });

  final String animationKind;
  final String? animationRef;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = ref.watch(
      resolvedAnimationProvider((kind: animationKind, ref: animationRef)),
    );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: resolved.when(
        loading: () => const _AnimationPlaceholder(
          icon: Icons.hourglass_top_rounded,
          label: 'Loading animation…',
        ),
        error: (_, _) => const _AnimationPlaceholder(
          icon: Icons.theaters_outlined,
          label: 'Animation unavailable',
        ),
        data: (r) => switch (r.source) {
          AnimationSource.asset => Lottie.asset(
                r.assetPath!,
                key: const Key('anim-lottie'),
                errorBuilder: (_, _, _) => const _AnimationPlaceholder(
                  icon: Icons.theaters_outlined,
                  label: 'Animation unavailable',
                ),
              ),
          AnimationSource.cached => Lottie.file(
                r.file!.path,
                key: const Key('anim-lottie'),
                errorBuilder: (_, _, _) => const _AnimationPlaceholder(
                  icon: Icons.theaters_outlined,
                  label: 'Animation unavailable',
                ),
              ),
          AnimationSource.needsDownload => const _AnimationPlaceholder(
                key: Key('anim-offline'),
                icon: Icons.cloud_off_rounded,
                label: 'Animation syncs when you’re online',
              ),
          AnimationSource.none => const _AnimationPlaceholder(
                key: Key('anim-placeholder'),
                icon: Icons.fitness_center_rounded,
                label: 'No animation',
              ),
        },
      ),
    );
  }
}

class _AnimationPlaceholder extends StatelessWidget {
  const _AnimationPlaceholder({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: context.textTertiary),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
