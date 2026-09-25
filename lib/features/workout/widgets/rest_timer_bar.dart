import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../application/workout_session_notifier.dart';

/// Slim bottom bar that hosts the rest countdown.
/// Renders nothing while idle so it can sit in `bottomNavigationBar`.
class RestTimerBar extends ConsumerWidget {
  const RestTimerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rest = ref.watch(restTimerProvider);
    if (!rest.running && !rest.finished) return const SizedBox.shrink();

    final finished = rest.finished;
    final accent = finished ? AppColors.gradeA : AppColors.accent;

    return Material(
      color: context.surfaceElevated,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rest.running)
              LinearProgressIndicator(
                value: rest.progress,
                minHeight: 3,
                backgroundColor: context.border,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (finished) ...[
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.gradeA, size: 20),
                    const SizedBox(width: 8),
                    const Text('Rest complete',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          ref.read(restTimerProvider.notifier).reset(),
                    ),
                  ] else ...[
                    const Icon(Icons.timer_outlined,
                        color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      rest.label,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => ref
                          .read(restTimerProvider.notifier)
                          .addSeconds(15),
                      child: const Text('+15s'),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.read(restTimerProvider.notifier).skip(),
                      child: const Text('Skip'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
