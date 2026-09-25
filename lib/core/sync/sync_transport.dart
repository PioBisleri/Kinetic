/// The persistence surface the sync engine needs from the remote side.
///
/// Rows are wire-format maps (snake_case keys, ISO-8601 UTC DateTimes, no
/// `synced_at`, no `user_id`): the transport owns auth scoping — it injects
/// the signed-in uid on writes and strips it from reads.
///
/// Children (routine slots, sets, muscle maps) are never synced row-by-row;
/// they ride their parent: a push replaces the remote child set wholesale,
/// which is also how hard local deletes propagate without a tombstone per row.
abstract class SyncTransport {
  /// Upsert [rows] into [table] (identified by `(user_id, id)` remotely).
  Future<void> upsert(String table, List<Map<String, dynamic>> rows);

  /// Make [rows] the complete child set of [parentIds] under [table]:
  /// every remote child of those parents is deleted first, then [rows] is
  /// inserted. Local absence = remote deletion.
  Future<void> replaceChildren(
    String table,
    String parentColumn,
    List<String> parentIds,
    List<Map<String, dynamic>> rows,
  );

  /// All rows of [table] whose `updated_at` is newer than [since]
  /// (tombstones included — they are rows with `deleted_at` set).
  Future<List<Map<String, dynamic>>> fetchChanged(
    String table, {
    required DateTime since,
  });

  /// All child rows of [table] whose [parentColumn] is in [parentIds].
  Future<List<Map<String, dynamic>>> fetchChildren(
    String table,
    String parentColumn,
    List<String> parentIds,
  );
}
