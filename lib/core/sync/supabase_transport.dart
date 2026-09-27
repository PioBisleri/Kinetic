import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_transport.dart';

/// [SyncTransport] over the Supabase (PostgREST) API.
///
/// Auth scoping lives here: every write injects `user_id` from the current
/// session, every read strips it again (RLS scopes the rows either way).
class SupabaseSyncTransport implements SyncTransport {
  SupabaseSyncTransport(this._client);

  final SupabaseClient _client;

  static const _pageSize = 1000;
  static const _idChunk = 100;

  /// Pagination needs a deterministic total order; `updated_at` alone can
  /// repeat across a page boundary (bulk writes share a timestamp), which
  /// would skip rows. Every parent table has a unique `id` to tiebreak on.
  static const _changedOrder = <String, String>{
    'profiles': 'id',
    'exercises': 'id',
    'routines': 'id',
    'workouts': 'id',
    'body_metrics': 'id',
  };

  /// Deterministic order for child pages. `exercise_muscle_map` has no `id`
  /// column — its PK suffix (`muscle_id`) is the tiebreak instead.
  static const _childOrder = <String, String>{
    'workout_sets': 'id',
    'routine_exercises': 'id',
    'exercise_muscle_map': 'muscle_id',
  };

  String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    return user.id;
  }

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.from(table).upsert([for (final r in rows) _scoped(r)]);
  }

  @override
  Future<void> replaceChildren(
    String table,
    String parentColumn,
    List<String> parentIds,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final chunk in _chunks(parentIds, _idChunk)) {
      await _client.from(table).delete().inFilter(parentColumn, chunk);
    }
    for (final chunk in _chunks(rows, _pageSize)) {
      await _client.from(table).upsert([for (final r in chunk) _scoped(r)]);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchChanged(
    String table, {
    required DateTime since,
  }) async {
    final tiebreak = _changedOrder[table] ?? 'id';
    final out = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      final page = await _client.from(table).select()
          .gt('updated_at', since.toUtc().toIso8601String())
          .order('updated_at', ascending: true)
          .order(tiebreak, ascending: true)
          .range(from, from + _pageSize - 1);
      out.addAll(page);
      if (page.length < _pageSize) break;
      from += _pageSize;
    }
    return [for (final r in out) _unscoped(r)];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchChildren(
    String table,
    String parentColumn,
    List<String> parentIds,
  ) async {
    final tiebreak = _childOrder[table] ?? 'id';
    final out = <Map<String, dynamic>>[];
    for (final chunk in _chunks(parentIds, _idChunk)) {
      var from = 0;
      while (true) {
        final page = await _client.from(table).select()
            .inFilter(parentColumn, chunk)
            .order(parentColumn, ascending: true)
            .order(tiebreak, ascending: true)
            .range(from, from + _pageSize - 1);
        out.addAll(page);
        if (page.length < _pageSize) break;
        from += _pageSize;
      }
    }
    return [for (final r in out) _unscoped(r)];
  }

  Map<String, dynamic> _scoped(Map<String, dynamic> row) => <String, dynamic>{
        ...row,
        'user_id': _uid,
      };

  Map<String, dynamic> _unscoped(Map<String, dynamic> row) {
    row.remove('user_id');
    return row;
  }

  static Iterable<List<T>> _chunks<T>(List<T> items, int size) sync* {
    for (var i = 0; i < items.length; i += size) {
      yield items.sublist(i, i + size > items.length ? items.length : i + size);
    }
  }
}
