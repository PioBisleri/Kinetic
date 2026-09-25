# Kinetic

A private, offline-first strength training tracker. No friends, no feed, no
followers — your data, your analytics, on your device.

## Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.47 (Dart 3.13) |
| State | Riverpod 3 (`Notifier` / `AsyncNotifier`) |
| Local DB | Drift (SQLite) — source of truth, WAL mode |
| Cloud | Supabase (Auth + Postgres + Storage), RLS-locked per user |
| Routing | go_router (4-tab stateful shell) |
| Charts | fl_chart (Phase 4) |

## Architecture

```
UI (Riverpod consumers)
  → Controllers / Notifiers (live session, rest timer, grade engine)
    → Repository layer (abstract)
      ├─ Drift/SQLite  ← LOCAL SOURCE OF TRUTH (always wins)
      └─ Supabase sync ← pull→push cycle, per-row last-write-wins
```

Rules:

- UUID keys generated client-side; every mutable table carries
  `updated_at / synced_at / deleted_at` (tombstone).
- The network is never a precondition for logging a set.
- All weights stored in **kg** internally; lbs is display-only.
- Exercise catalog is seeded from bundled JSON — fully usable on a plane.

## Cloud sync (Phase 7)

Email auth + offline-first sync. The local DB stays the source of truth;
a sync cycle is **pull → push**:

- **Dirty scan push** — rows with `synced_at IS NULL OR updated_at >
  synced_at` upload via upsert, then mark clean with
  `WHERE id AND updated_at` (a concurrent edit keeps the row dirty).
- **Children ride parents** — sets, routine slots and muscle-map rows are
  never uploaded row-by-row: pushing a parent runs `replaceChildren`
  (remote children of those parents deleted, current local set inserted).
  That is also how hard deletes propagate — every child mutation bumps the
  parent's `updated_at` (`WorkoutSessionNotifier._touchWorkout`), so the
  parent pushes and its remote children mirror the device exactly.
- **Tombstones** — soft deletes (`deleted_at` + `updated_at` bump) are
  ordinary dirty rows; they push as-is and are never hard-deleted remotely.
  On pull, a remote tombstone applies locally only if the row exists here.
- **Pull** — cursor in SharedPreferences (`sync.cursor.<uid>`, 15-min
  overlap), per-row LWW: incoming wins only when `updated_at` is strictly
  newer. Winners fetch their children and apply parent+children in one
  local transaction (pre-marked `synced_at = updated_at` — no echo push).
  In-progress (`active`) workouts are not imported until they complete.
- **Rollups** — pull re-derives analytics days touched by changed sets
  inside the same transaction.
- **Triggers** — manual button (Profile → Sync), after sign-in, and on
  app resume. Failures surface in the UI; nothing local is lost offline.

Remote schema: `supabase/schema.sql` — RLS-locked per `auth.uid()`,
composite PK `(user_id, id)`, one policy per table. Rollup tables,
`muscle_groups` and `sync_queue` are intentionally not synced.

Setup:

```bash
# 1. Paste supabase/schema.sql into the Supabase SQL editor and run it.
# 2. Build with the project's URL + anon key:
flutter build apk \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key>
```

Without the dart-defines the app runs fully local and Profile shows
"Cloud sync not configured". Cross-device sync is tested offline against
`FakeSyncTransport` (`test/sync_engine_test.dart`); the Supabase transport
is a thin PostgREST wrapper over the same interface.

**Export** — Profile → Data: full JSON backup (profile, exercises with
muscle map, routines with slots, workouts with sets) and a CSV of every
set, shared through the OS share sheet (`share_plus`). Weights in the CSV
are always kg.

**Light theme** — widget code reads semantic colors through
`context.textPrimary` etc. (`AppColorsContext` in `app_theme.dart`);
dark keeps the original constants pixel-for-pixel, light gets readable
values.

## Project layout

```
lib/
  main.dart                  boot order: DB → seed → prefs → optional Supabase
  app.dart                   MaterialApp.router + 4-tab NavigationBar
  core/
    database/database.dart   12-table Drift schema + query helpers
    database/seed_service.dart  bundled JSON → SQLite (idempotent)
    export/export_service.dart  pure JSON/CSV builders + share-sheet writer
    settings/settings.dart   units, theme, plate set (SharedPreferences)
    sync/sync_engine.dart    pull → push cycle (LWW, children ride parents)
    sync/sync_transport.dart  remote interface; supabase_transport.dart = impl
    sync/sync_providers.dart  config flag, engine, auth, SyncController
    theme/app_theme.dart     dark-first design tokens, grade/heat colors
    utils/plate_calculator.dart  integer-gram DP plate optimizer
  features/
    home/                    start workout + stat cards
    routines/                filterable exercise library (builder → Phase 3)
    analytics/               analytics tab: charts + rollups
    analytics/domain/grade_engine.dart  pure grade math (unit-tested)
    analytics/domain/analytics_math.dart  buckets, streaks, date math
    analytics/application/rollup_service.dart  day-recompute rollup writer
    analytics/application/analytics_providers.dart  window/trend streams
    analytics/widgets/charts.dart  fl_chart volume/strength + calendar
    profile/                 settings, sync/auth, export, privacy statement
supabase/schema.sql           remote DDL: composite PKs + RLS per auth.uid()
assets/seed/
  muscle_groups.json         19 muscles, heat-map nodes, balance pairs
  exercises.json              89 exercises with weighted contributions
```

## Muscle Grade algorithm

Per muscle, rolling 30-day window:

```
score = 0.40·volume + 0.40·strength + 0.20·consistency     (0–100)

volume       = 100·ln(1 + V/1000) / ln(1 + target/1000)     target = 8000 kg/wk × 4.33
strength     = 100·(e1RM / (BW × standard))^0.8             Epley: w·(1 + reps/30)
consistency  = 100·(days/target)·(0.6 + 0.4·freshness)      freshness fades over 72 h

S ≥ 90 · A ≥ 78 · B ≥ 64 · C ≥ 48 · D ≥ 30 · F < 30
```

Volume is attributed per-muscle via `exercise_muscle_map.contribution`
(bench: chest 1.0, triceps 0.5, front delts 0.4). The same freshness term
drives the body heat map (red → grey over 48–72 h).

## Roadmap

- **Phase 1 ✅** foundation, schema, seed catalog, shell, grade/plate engines
- **Phase 2 ✅** live workout logger (sets, RPE, rest timer, plate calculator UI,
  supersets, notes)
- **Phase 3 ✅** routine builder (drag-and-drop, targets, warm-ups)
- **Phase 4 ✅** analytics & charts (weekly volume, 1RM progression,
  consistency calendar, `ExerciseHistory`/`MuscleVolumeDaily` rollups written
  on every set mutation + boot backfill)
- **Phase 5 ✅** body heat map (red→grey 72h silhouette) + Muscle Grade
  dashboard (F–S tiers, balance ratios fixed) + bodyweight input in Profile
- **Phase 6 ✅** animations (Tier-0 Lottie bundled / Tier-1 streamed, offline
  cache + placeholders) + custom exercises (create/edit, muscle map, tombstone
  delete) — also fixed a seed bug where the `chest` group row clobbered the
  chest heat-map nodes
- **Phase 7 ✅** Supabase sync engine (email auth, pull→push LWW, children
  ride parents, tombstones, RLS `schema.sql`, offline-tested with fake
  transport) + export (JSON backup / CSV via share sheet) + light theme
  polish (semantic colors bound to the theme)
- **Phase 8 ✅** smart logging + device integration — next-weight suggestion
  engine (double progression + auto-deload, kg-native, plate-grid snapped)
  with a tap-to-apply chip in the set editor; exercise progress screen
  (e1RM/volume trend chart, all-time PR tiles, last-vs-previous session
  deltas); AMOLED true-black option; "Start Workout" home-screen shortcut;
  weekly workout reminders (timezone-scheduled, exact when the platform
  allows, boot re-arm via `ScheduledNotificationBootReceiver`)
- **Phase 9** home-screen widget + volume landmarks
- **Phase 10** end-to-end encrypted sync (before the Supabase project goes
  live — `schema.sql` must not be run until then)

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after schema edits
flutter analyze
flutter test
flutter run
```
