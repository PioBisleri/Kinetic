import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/database.dart';

/// Completion flag for the first-run setup. Existing installs are migrated
/// to "done" as soon as any real user data is present.
const onboardingDoneKey = 'onboarding_done';

/// Whether the router should open on `/onboarding`.
///
/// Defaults to false so widget tests and existing installs boot straight to
/// the shell. `main()` overrides this after inspecting the database.
final onboardingPendingProvider = Provider<bool>((ref) => false);

/// Resolve first-run state without ever trapping an existing user:
/// a missing flag is only treated as "new" when there is no profile,
/// workout history or body-metric history yet.
Future<bool> resolveOnboardingPending(
  AppDatabase db,
  SharedPreferences prefs,
) async {
  if (prefs.getBool(onboardingDoneKey) ?? false) return false;

  final hasProfile = await db.select(db.profiles).getSingleOrNull() != null;
  final hasWorkout = (await (db.select(
    db.workouts,
  )..limit(1)).get()).isNotEmpty;
  final hasBodyMetric = (await (db.select(
    db.bodyMetrics,
  )..limit(1)).get()).isNotEmpty;

  if (hasProfile || hasWorkout || hasBodyMetric) {
    await prefs.setBool(onboardingDoneKey, true);
    return false;
  }
  return true;
}
