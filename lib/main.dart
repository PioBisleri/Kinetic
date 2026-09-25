import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/database/database.dart';
import 'core/database/seed_service.dart';
import 'core/notifications/rest_notification_service.dart';
import 'core/notifications/weekly_reminder_service.dart';
import 'core/settings/settings.dart';
import 'core/sync/sync_providers.dart';
import 'features/analytics/application/rollup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Local database FIRST — the app must boot fully offline.
  final db = AppDatabase();

  // 2. Seed muscle groups + exercise catalog on first launch (bundled JSON).
  await SeedService(db).ensureSeeded();

  // 2b. Repair analytics rollups for any pre-rollup data (no-op normally).
  await RollupService(db).backfillIfNeeded();

  // 3. Settings are synchronous reads at startup.
  final prefs = await SharedPreferences.getInstance();

  // 4. Supabase is optional at boot; failure must never block the UI.
  var supabaseConfigured = false;
  try {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isNotEmpty && key.isNotEmpty) {
      await Supabase.initialize(url: url, publishableKey: key);
      supabaseConfigured = true;
    }
  } catch (_) {
    // Offline / not configured — local mode still works.
  }

  // 5. Rest-timer notifications (guarded; no-ops if permission denied).
  final notifications = RestNotificationService(enabled: true);
  await notifications.init();

  // Weekly workout reminder channel — enabled instance; arming/cancelling
  // is driven by settings (and re-armed at startup, see KineticApp).
  final reminder = WeeklyReminderService(enabled: true);

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        restNotificationProvider.overrideWithValue(notifications),
        weeklyReminderProvider.overrideWithValue(reminder),
        // Only true when the dart-defines were present AND initialize above
        // succeeded — providers below use this to avoid touching
        // `Supabase.instance`, which asserts when uninitialized.
        supabaseConfiguredProvider.overrideWithValue(supabaseConfigured),
      ],
      child: const KineticApp(),
    ),
  );
}
