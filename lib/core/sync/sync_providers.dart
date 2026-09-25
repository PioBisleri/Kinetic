import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/analytics/application/rollup_service.dart';
import '../../features/analytics/domain/analytics_math.dart' show dayOf;
import '../database/database.dart';
import '../settings/settings.dart';
import 'supabase_transport.dart';
import 'sync_engine.dart';
import 'sync_transport.dart';

/// Set by `main.dart` only after `Supabase.initialize` succeeded with a
/// non-empty `--dart-define` URL/key. `Supabase.instance` asserts when
/// unconfigured, so everything below gates on this flag first.
final supabaseConfiguredProvider = Provider<bool>((ref) => false);

final syncTransportProvider = Provider<SyncTransport?>((ref) {
  if (!ref.watch(supabaseConfiguredProvider)) return null;
  return SupabaseSyncTransport(Supabase.instance.client);
});

final syncEngineProvider = Provider<SyncEngine?>((ref) {
  final transport = ref.watch(syncTransportProvider);
  if (transport == null) return null;
  final db = ref.watch(databaseProvider);
  return SyncEngine(
    db: db,
    transport: transport,
    recompute: (times) async {
      final rollups = RollupService(db);
      final days = <DateTime>{for (final t in times) dayOf(t)};
      for (final day in days) {
        await rollups.recomputeDay(day);
      }
    },
  );
});

/// Auth changes. Emits an empty stream while sync is not configured so UI
/// can watch this unconditionally.
final authStateProvider = StreamProvider<AuthState>((ref) {
  if (!ref.watch(supabaseConfiguredProvider)) return const Stream.empty();
  return Supabase.instance.client.auth.onAuthStateChange;
});

class SyncState {
  const SyncState({this.running = false, this.lastSyncAt, this.lastError});

  final bool running;
  final DateTime? lastSyncAt;
  final String? lastError;

  bool get hasError => lastError != null;
}

/// Serializes sync cycles (manual button, sign-in, app resume all funnel in
/// here) and persists the pull cursor per signed-in uid.
class SyncController extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState();

  Future<void> syncNow() async {
    final engine = ref.read(syncEngineProvider);
    if (engine == null || state.running) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return; // signed-out UX owns this state

    state = const SyncState(running: true);
    final prefs = ref.read(sharedPreferencesProvider);
    final cursorKey = 'sync.cursor.${user.id}';
    final since = DateTime.tryParse(prefs.getString(cursorKey) ?? '');
    try {
      final result = await engine.sync(since: since);
      await prefs.setString(cursorKey, result.startedAt.toIso8601String());
      state = SyncState(lastSyncAt: result.startedAt);
    } catch (e) {
      state = SyncState(lastSyncAt: state.lastSyncAt, lastError: '$e');
    }
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncState>(SyncController.new);
