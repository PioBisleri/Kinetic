# Phase 10 — End-to-End Encrypted Sync

> Design doc only. No code in this round. The Supabase project is **not live**
> and `supabase/schema.sql` has **never been applied** — this must land first.

---

## 1. Threat model

The server (Supabase) is treated as **untrusted storage**. The user's workout
data — exercises, routines, sets, body metrics, profile — must be unreadable
to anyone with database access (including us). The server sees only ciphertext
plus the plaintext columns PostgREST needs for filtering (`id`, `updated_at`,
`user_id`, parent FKs).

**Not in scope:** device compromise, screen capture, traffic analysis.

---

## 2. Key derivation — Argon2id passphrase

The user sets a sync passphrase (minimum 8 chars). The encryption key is
derived client-side with **Argon2id**:

```
key = Argon2id(
  passphrase,
  salt = SHA-256("kinetic-sync-v1" + user_id),   // deterministic per user
  memory = 64 MB,
  iterations = 3,
  parallelism = 4,
  output = 32 bytes (AES-256)
)
```

The salt is derived from the user's auth uid so it's stable across devices
without being stored. The passphrase never leaves the device.

**Package:** `cryptography` (pure Dart, supports Argon2id + AES-GCM).

---

## 3. Encryption seam — `SyncCodec.encode/decode`

Every row passes through exactly these two statics. A payload-level
encrypt/decrypt wrapper here leaves `SyncEngine` and `SupabaseSyncTransport`
untouched.

### What stays plaintext (PostgREST filters on these)

| Column | Why |
|---|---|
| `id` | primary key, `WHERE` clauses |
| `updated_at` | LWW comparison, `since` cursor |
| `synced_at` | dirty-scan (`IS NULL OR updated_at > synced_at`) |
| `user_id` | auth scoping |
| parent FKs (`routine_id`, `exercise_id`, `workout_id`) | `fetchChildren` filters |

### What gets encrypted

All other columns are serialized to a JSON blob, encrypted with AES-256-GCM,
and stored in a single `payload` column (base64). The wire row becomes:

```json
{
  "id": "uuid",
  "updated_at": "2026-09-29T10:00:00Z",
  "user_id": "auth-uid",
  "routine_id": "uuid",        // parent FK stays plaintext
  "payload": "base64(nonce + ciphertext + tag)"
}
```

### `SyncValueSerializer` interaction

The current serializer assumes DateTimes on the wire. With encryption, the
payload is a JSON blob of the *original* Dart values (DateTime objects
included), so the serializer runs **before** encryption on encode and **after**
decryption on decode. No change needed — just ensure the order is right.

---

## 4. Wire format v2

A `format` column (default `1`) on each synced table lets the server serve
both encrypted and unencrypted rows during migration. The transport reads
`format` and decrypts when `format = 2`.

Older clients ignore `format = 2` rows (they can't decrypt them). Newer
clients read both. This allows a rolling migration without a hard cutover.

---

## 5. Key rotation

The user can change their sync passphrase from Settings. Rotation re-encrypts
all local rows with the new key:

1. Derive new key from new passphrase.
2. Read all rows (decrypt with old key).
3. Re-encrypt with new key, bump `updated_at`.
4. Push to server (LWW overwrites old ciphertext).

The old key is discarded. Rows still on the server with the old key become
unreadable after the push completes — acceptable, since the push overwrites
them.

---

## 6. Lost-key recovery

**There is no recovery.** The passphrase is the only way to derive the key.
If lost, the user must:

1. Delete all synced data from the server (Settings → "Reset sync").
2. Set a new passphrase.
3. Re-push from the device (local data is untouched).

This is documented in the sync setup flow: "Your passphrase is the only key
to your synced data. If you lose it, synced data cannot be recovered."

---

## 7. `minSyncVersion`

The Round-1 decision set `minSyncVersion = 24` as a sync-compat floor. This
value is **not present in the Dart code today**. Phase 10 must:

1. Confirm or re-derive the value (it likely refers to the Supabase schema
   version or a protocol version — clarify in code comments).
2. Add it as a constant in `sync_engine.dart` or a new `sync_constants.dart`.
3. Check it on pull: if the server reports a lower version, refuse to sync.

---

## 8. Rollout order

1. **This doc** — agree on the design.
2. **Implement encryption** in `SyncCodec` + `cryptography` package.
3. **Add `format` column** to `supabase/schema.sql` (all 8 synced tables).
4. **Apply `schema.sql`** to the Supabase project (first time ever).
5. **Key setup flow** in Settings → Sync section.
6. **E2E test** with a real device: push, pull, verify ciphertext on server.
7. **Key rotation** UI.
8. **Lost-key** reset flow.

---

## 9. Open questions

| # | Question | Default answer |
|---|---|---|
| 1 | Should the passphrase be required or optional? | Optional — sync is opt-in, encryption is mandatory when sync is on. |
| 2 | What if the user has no passphrase and sync is off? | No encryption, no sync — current behavior. |
| 3 | Should we encrypt `body_metrics` (weight trend)? | Yes — it's health data. |
| 4 | How to handle schema migrations with encrypted payloads? | Payload is opaque JSON — schema changes don't affect it. |
| 5 | Should we add a "verify passphrase" step? | Yes — decrypt a known test row on setup. |

---

## 10. Files that will change

| File | Change |
|---|---|
| `lib/core/sync/sync_codec.dart` | Add `encrypt()`/`decrypt()` wrapper |
| `lib/core/sync/sync_engine.dart` | Add `minSyncVersion` constant |
| `lib/core/sync/sync_providers.dart` | Key derivation + storage |
| `lib/features/settings/sync_section.dart` | Passphrase setup, rotation, reset |
| `pubspec.yaml` | Add `cryptography` dependency |
| `supabase/schema.sql` | Add `format` column to 8 tables |
| `test/sync_engine_test.dart` | Encryption round-trip tests |
