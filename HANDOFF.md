# Kinetic — Build Handoff & Progress Log

> Offline-first fitness tracker (Hevy-like), personal analytics only — **no social
> features, ever**. This file exists so the project can move to another machine
> without losing context. Last updated: **2026-09-29**, at **v0.1.4+4**,
> schema **v8**, **278 tests green**, all CI runs **passing**.

---

## 1. Where things stand right now

| Item | State |
|---|---|
| Version | `0.1.4+4` (`pubspec.yaml`) |
| DB schema | **v8** (`AppDatabase.schemaVersion`) |
| Tests | **278 passing**, 45 test files, `flutter analyze` clean |
| Repo | `main` @ `9e33586`, working tree clean |
| Remote | `origin` = `git@github.com:PioBisleri/Kinetic.git` (public) |
| Pushed | everything **through `9e33586`** (this handoff doc) |
| CI | GitHub Actions `CI` — all runs `conclusion: success` (analyze + test on Flutter 3.47.5) |
| Supabase | **project NOT live**, `supabase/schema.sql` **never applied** (by design, see §10) |
| Device | `R9ZY305521H`; release APK signed with the **debug key** (intentional) |

✅ **All commits are pushed** — a fresh clone of `origin/main` gives the full state.

---

## 2. Setting up a fresh machine

**NixOS (recommended)**

```bash
cd kinetic
direnv allow          # one-time per machine; loads flake.nix dev shell
```

The flake provides Flutter 3.47.5, Android SDK (platforms 35/36, build-tools
36.0.0, NDK 28.2.13676358, cmake 3.22.1), JDK 17, and sqlite3. Nothing else to
install. `direnv` must be on PATH and `~/.config/direnv/direnvrc` must source
`hm-nix-direnv.sh` (already configured on this machine).

**Non-NixOS / manual**

**Prerequisites**

- Flutter **3.47.5** stable (CI pins this; `pubspec.yaml` wants Dart `^3.13.4`)
- Android SDK + `adb` (device builds/install)
- Nothing else — the app is fully offline; **no Supabase account is needed** to
  build or test (sync says "not configured" without dart-defines).

**First commands after clone**

```bash
cd kinetic
export PATH="$HOME/development/flutter/bin:$PATH"   # adjust to your Flutter path
flutter --no-version-check pub get
flutter --no-version-check analyze
flutter --no-version-check test          # expect: 278 passing
```

⚠️ **Always pass `--no-version-check`.** The tool's periodic update check does a
`git fetch` to github.com; when the network was down this hung the CLI outright
(network has been intermittent on the build machine — ssh/GitHub work now, but
the flag is a cheap insurance policy and is baked into `build-apk.sh`).

**Build & install**

```bash
./build-apk.sh                 # -> kinetic-v0.1.4.apk (version read from pubspec)
adb install -r kinetic-v0.1.4.apk
```

`build-apk.sh` runs `flutter build apk --release --no-version-check "$@"`,
then **copies** (never moves) `build/app/outputs/flutter-apk/app-release.apk`
to `kinetic-v<version>.apk` in the repo root. Extra args pass through, e.g.:

```bash
./build-apk.sh --dart-define=SUPABASE_URL=https://<proj>.supabase.co \
               --dart-define=SUPABASE_ANON_KEY=<key>
```

`kinetic-v*.apk` is gitignored. The `build/` dir (~1.6 GB) is gitignored — rebuild.

---

## 3. Everyday commands

```bash
export PATH="$HOME/development/flutter/bin:$PATH"

flutter --no-version-check analyze                # linter (must stay clean)
flutter --no-version-check test                   # full suite (276)
flutter --no-version-check test test/foo_test.dart   # single file
dart run build_runner build --delete-conflicting-outputs   # after ANY schema edit
./build-apk.sh                                    # release APK with versioned name
```

**Running tests:** avoid piping long runs through `tail` — output buffers until
exit and timeouts become undiagnosable. For the full suite, run it in the
background with streaming output. If a run seems hung, first check for stale
dart processes (`ps aux | grep -E "[d]art|[f]lutter"`) — servers/shells have
been restarted mid-run and left zombies.

---

## 4. Architecture

**Stack:** Flutter (Dart ^3.13) · **Riverpod 3** (`Notifier`/`AsyncNotifier`) ·
**Drift 2.35** (SQLite via FFI) · `go_router` 18 · `fl_chart` · `supabase_flutter` 2.17 ·
`flutter_local_notifications` · `home_widget` · `share_plus`.

**Offline-first:** local SQLite is the single source of truth; the network is
never a precondition for logging a set. All weights stored in **kg**; lbs is
display-only. Seed catalog (19 muscle groups, 89 exercises) ships as bundled
JSON in `assets/seed/` and seeds on first launch.

**Layout**

```
lib/
  app.dart                       # go_router routes, drawer shell, version string
  core/
    database/database.dart       # ALL Drift tables, schemaVersion, onUpgrade
    database/database.g.dart     # generated (build_runner)
    database/delete_service.dart # granular + full wipe (reseeds catalog)
    export/                      # export_service (JSON/CSV) + import_service
    sync/                        # sync_engine, sync_codec, supabase_transport
    services/                    # rest timer, notifications, reminders…
  features/
    workout/                     # live logger, set editor, suggestions, plates
    routines/                    # builder, library, weekly plan (/schedule)
    analytics/                   # charts, grade board, heat map, landmarks
    profile/                     # Profile page, Your data, weight trend, settings
    settings/ …
assets/seed/                     # exercises.json, muscle_groups.json
supabase/schema.sql              # remote DDL — NOT applied (Phase 10 gate)
.github/workflows/ci.yml         # analyze + test, Flutter 3.47.5, ubuntu + sqlite3
```

**Routes:** tabs `/`, `/routines`, `/analytics`, `/profile`; plus `/workout`,
`/library` (+ `/:id`, `/new`, `/:id/edit`), `/settings`, `/schedule`,
`/routines/new`, `/routines/:id`.

**Gotcha:** files under `lib/features/analytics/widgets/` import core as
`../../../core/...`, while `../application/` and `../domain/` are one level up.
`databaseProvider` is defined in `core/database/database.dart`
(**not** `database_providers.dart`).

---

## 5. Database schema history

| v | Added | Migration branch notes |
|---|---|---|
| 1 | base tables (profiles, exercises, muscle map, routines, entries, workouts, sets, rollups, sync queue) | — |
| 2 | `weekly_plans` | view-only weekly plan |
| 3 | set `type` counts + `rest_seconds` columns | warm-up entries backfilled; `rest_seconds = -1` = inherit sentinel |
| 4 | Profile "Your data" columns (height, dob, sex, body fat, goal…) | existing row untouched |
| 5 | `exercises.progression_increment_kg` | nullable = inherit |
| 6 | `body_metrics` table (id = local dayKey) | **backfills today's point from profile weight** (skips if none) |
| 7 | `volume_landmarks` | **create-only, no backfill** — override rows only; absent row ⇒ curated default |
| 8 | drop `sync_queue` | never-used table removed; `DROP TABLE IF EXISTS sync_queue` |

Tables (15): `profiles, body_metrics, volume_landmarks, muscle_groups, exercises,
exercise_muscle_map, routines, routine_exercises, weekly_plans, workouts,
workout_sets, muscle_volume_daily, exercise_history, muscle_grade_history`.

**Migration rules**

- All schema changes live in code via Drift's gated `onUpgrade` — migrations are
  **never** applied via SQL file.
- Each new version = one `if (from < N)` branch, and older tests
  (`v1 → N`) must replay every earlier branch.
- After a partial `onUpgrade(from, to)` with `to < schemaVersion`, drift reads of
  not-yet-altered tables fail — use raw SQL in migration tests, or run to current.
- **After any schema edit:** run build_runner (§3) and add a migration test.

**`supabase/schema.sql`** holds only the 8 **synced** tables (profiles, exercises,
exercise_muscle_map, routines, routine_exercises, workouts, workout_sets,
body_metrics). **Local-only** and therefore intentionally absent: `weekly_plans`,
`volume_landmarks` (plus rollups and the seeded muscle_groups).
It must **not** be applied to the Supabase project before Phase 10.

---

## 6. Delivery history (what was built, in order)

**Phases 1–8 (foundation → release-ready)**
1. Foundation, schema, seed catalog, shell, grade/plate engines
2. Live logger: sets/RPE/notes, rest timer, plate UI, supersets
3. Routine builder: drag-and-drop, targets, per-type set counts (warm-up/working/drop/failure)
4. Analytics: volume, 1RM, calendar, rollups (`recomputeDay`, `backfillIfNeeded`)
5. Body heat map + Muscle Grade dashboard + bodyweight input
6. (Lottie animations later removed in Round 2 — "D1: remove Lottie animation feature entirely") + custom exercises
7. Supabase sync engine (auth, pull→push LWW, tombstones, children-ride-parents, offline-tested with fake transport) + export + light theme
8. Smart logging (next-weight suggestions w/ double progression + auto-deload, exercise progress), AMOLED mode, quick action, weekly reminders

**Round 2 — UX pass:** left drawer + Settings page split from Profile;
ranked smart search (exact > prefix > word > substring > fuzzy, synonyms,
typos); view-only weekly plan at `/schedule` (schema v2); ultra-flat hairline
design (radius 4–6, teal accents); reactive providers; animations removed.

**Round 3 — `cf5c5b4` (v0.1.1):** Hevy-style custom set types per routine entry
(steppers, working sets derived from total) + three-tier rest precedence
(routine → exercise → app settings; schema v3, `rest_seconds = -1` inherit).

**Round 4 — `8ae2ba5`/`7b28319` (v0.1.2):** frosted-glass drawer (blur +
token tint over active tab), tab shortcuts, Start Workout / Exercise Library
drawer entries.

**Round 5 — `4fb3773`/`9651a8a`/`26d8642`/`0c6022a`/`e41c1bc` (v0.1.3):**
Profile "Your data" + derived BMI (schema v4); grade transparency (breakdown
sheets, "How grades work", suggestion why-sheet); GitHub Actions CI;
Android 4×2 home-screen widget (volume/streak/next-up, tap boots logger).

**Round 6 — v0.1.4 (complete):**
- **6A `e536287`** — per-exercise progression increments (schema v5):
  `exercises.progression_increment_kg` nullable ⇒ inherit; editor "Load
  increment" row; `Suggestion.incrementKg`; set-editor ± follows the override.
- **6B `c241834`** — bodyweight trend (schema v6): `body_metrics` (id = dayKey),
  backfill today from profile weight, capture hook on profile bodyweight save,
  export key `bodyMetrics`, flat LWW sync, 12-week trend sheet (stats +
  fl_chart raw line + dashed trailing 7-day avg), Profile row
  `profile-weight-trend`. Also repaired `schema.sql` (had been missing
  `exercises.rest_seconds` / `progression_increment_kg`).
- **6C `124aad7`** — volume landmarks (schema v7): RP/Israetel-style
  MEV/MAV/MRV **editable defaults** for all 18 gradeable muscles; Analytics
  card with 4-zone band track (gray < MEV · teal MEV–MAV · warm MAV–MRV · hot
  > MRV) + marker dot at current period's sets; info sheet (definitions,
  counting rule, legend) + edit sheet (validated `1 ≤ MEV < MAV < MRV ≤ 99`,
  reset-to-default); subtitle follows period chips (4W/12W/6M/All, default 12);
  export key `volumeLandmarks`; wiped by `deleteAllData`; local-only (not in
  schema.sql).
- **`281119b`** — README refresh (badges 246→276, Round 6 history, Phase 9
  retired from roadmap).
- **`134a231`** — release: bump version to 0.1.4 (6 places, see §9).
- **`cbaf43e`** — `build-apk.sh` versioned APK naming + gitignore + README.

**Round 7 — v0.1.5 (in progress):**
- **7A** — Nix dev shell (`flake.nix` + `direnv`): Flutter 3.47.5, Android SDK
  (platforms 35/36, build-tools 36.0.0, NDK 28.2.13676358, cmake 3.22.1), JDK 17,
  sqlite3. Pinned to nixpkgs PR #567033 head until 3.47.5 lands in nixos-unstable.
- **7B** — KGP warning resolved: `android.builtInKotlin=true` (both plugins already
  gate on it). Flutter CLI warning is a false positive (static scan).
- **7C** — schema v8: dropped never-used `sync_queue` table (16 → 15 tables).
  Migration test added.

---

## 7. Design decisions & hard rules (do not break)

- **No social features.** Not in the codebase. Period.
- **kg is canonical** in storage; lbs/lb plates are display/UX only.
- **Import = JSON-only, replace-all** (older backups normalize on the way in).
- App id `com.kinetic.kinetic`; release APKs signed with the **debug** key.
- **Aesthetic:** dark-first, minimalist, ultra-flat hairline UI (radius 4–6),
  teal accents on controls, translucent/blurred drawer ("frosted glass" over
  the active tab). App-consistent palette; flat = no heavy cards/shadows.
- **Transparency:** grades/suggestions must expose their math via sheets.
- **Local-only ≠ sync:** weekly plan and volume landmarks never sync and are
  deliberately absent from `schema.sql`; everything synced uses LWW on
  `updatedAt`, tombstones (`deletedAt`), children-ride-parents, wire codec
  (camelCase ↔ snake_case, UTC ISO-8601 DateTimes, local `uid` re-injected).
- Round 1: `flutter.minSyncVersion = 24` was agreed as a sync-compat floor.
  It is **not present in the Dart code today** — re-derive/confirm it in
  Phase 10.
- Grade math = `0.40·volume + 0.40·strength + 0.20·consistency`, with a
  parent-touch invariant (touching a child bumps the parent's `updatedAt`).
  Volume component is **global-kg**, which is why sets-based landmarks don't
  conflict with it.

---

## 8. Analytics specifics worth remembering

- Period chips: `(4,'4W'), (12,'12W'), (26,'6M'), (0,'All')`, **default 12**;
  `periodStart(0)` = epoch (All).
- `body_metrics.id` = local dayKey (string), wall-clock `updatedAt`.
- Landmark scale end = **1.25 × MRV** (marker fraction clamped to 0..1).
- 18 gradeable muscles — `landmarkDefaults` must cover each exactly once
  (asserted by test).
- Charts on Analytics are built lazily by the page `ListView` — inserting tall
  cards changes what's built at the initial scroll position (see §9).

---

## 9. Testing & known pitfalls

**Suite:** 276 tests / 44 files. Migration tests, widget tests (pump the real
shell), sync tests with a **fake transport** (never hits network), export/import
round-trips, delete-service wipes.

Recurring traps, all hit the hard way:

1. **`--no-version-check`** on every flutter command (§2).
2. **Widget-test `ListView` cache extent** — a tall widget inserted mid-page
   pushes later cards outside the build window ⇒ `find.byType(...)` finds 0.
   Fix: `tester.scrollUntilVisible(...)` before asserting (see
   `test/analytics_page_test.dart`).
3. **Duplicate widget keys** — `ChartCard`'s info button defaulted to
   `Key('chart-info')`; two cards with it made taps ambiguous. `ChartCard` now
   takes an `infoKey` param (default unchanged); the landmarks card passes
   `landmarks-info`. Give every interactive widget a **unique** key when a page
   can show several.
4. **`flutter test | tail`** buffers everything until exit → useless on timeout.
   Stream to a file instead; background long runs.
5. **Shell/server restarts kill background jobs** — check for stale dart
   processes before relaunching.
6. **Migration tests:** partial `onUpgrade` to an older version leaves later
   columns missing; use raw SQL or upgrade fully.
7. **build_runner required after schema edits** (`database.g.dart`).
8. **Version bump touches 6 places:** `pubspec.yaml`, `README.md` (title line 1
   + version badge), `lib/app.dart` (drawer footer `'Kinetic 0.1.x ·
   offline-first'`), `lib/features/profile/profile_page.dart` (`Version 0.1.x`),
   `test/drawer_test.dart` (asserts the footer text). Plus the tests badge and
   delivery-history line in README when the count/round changes. All README
   badges are **static shields.io images** — edit by hand.

**CI:** `.github/workflows/ci.yml` — `flutter-action@v2` pins **3.47.5**,
installs `libsqlite3-0 libsqlite3-dev`, then `pub get` + `analyze` + `test`.
Triggered on push to main / PR / manual. If you bump the Flutter version
locally, bump CI too.

---

## 10. Sync model & Phase 10 (the next big thing)

**Today (works, offline-tested):** `lib/core/sync/` contains `sync_engine`
(pull→push, `since` cursor + overlap re-read, dirty-scan on
`synced_at IS NULL OR updated_at > synced_at`, per-row LWW), `sync_codec`
(wire format), `supabase_transport` / `sync_transport` (fake in tests).
Synced tables: profiles, exercises, exercise_muscle_map, routines,
routine_exercises, workouts, workout_sets, body_metrics. In-progress workouts
are not pushed until finished. Deeply tested in `test/sync_engine_test.dart`
(encode/decode, tombstones, LWW both directions, children ride parents,
cursor overlap…).

**Not yet done — Phase 10: end-to-end encrypted sync.**

- Supabase project is **not live**; `schema.sql` (8 tables) has **never been
  applied**. All migrations must remain code-side.
- E2E encryption must land **before** the Supabase project goes live: keys are
  derived client-side, the server only ever sees ciphertext. Design questions
  still open: key derivation (passphrase? device-held?), key rotation,
  what happens on lost keys, and how the wire codec changes (encrypt
  payloads vs fields).
- Round-1 decision to re-confirm: sync schema-compat floor
  `minSyncVersion = 24`.
- After Phase 10: apply `schema.sql`, then verify real-device sync E2E.

**Roadmap (only Phase 10 remains).**

---

## 11. Watchlist / tech debt

- ✅ **KGP warning resolved (Round 7):** `android/gradle.properties` now sets
  `android.builtInKotlin=true`. Both plugins (`flutter_timezone` 5.1.0,
  `home_widget` 0.10.0) already gate their legacy KGP apply on this flag, so
  neither applies KGP anymore — verified by a successful release build. The
  Flutter CLI still prints the KGP warning because its static scan doesn't
  understand the plugins' Groovy conditionals; this is a false positive that
  disappears when the plugins drop the legacy code path.
- Network on the build machine has been flaky historically (git fetches
  hanging); the CLI flag and CI are the workarounds.
- 15 packages have newer (non-breaking-constraint) versions —
  `flutter pub outdated` when convenient; none urgent.
- CI is verified green through `124aad7`; the final 3 commits will run CI on
  push.
- On-device UI checks always fall to human eyes — install and click through
  after each round.

---

## 12. Release checklist (as done for v0.1.4)

1. All phases of the round committed; full suite green (276+), analyze clean.
2. Bump version in the **6 places** (§9.7), tag delivery-history line in README.
3. Update README tests badge (`N%20passing`) + the `flutter test # N tests` line.
4. Commit `release: bump version to 0.1.x`.
5. `./build-apk.sh` → `kinetic-v0.1.x.apk` → `adb install -r`.
6. `git push origin main` → confirm CI run goes green on GitHub.
7. Deliver a short release note to the user.

**v0.1.4 release note (for reference):**
> Load increments that fit the bar (per-exercise kg/lb step) · Bodyweight
> trend (12-week weigh-in chart, 7-day average) · Volume landmarks
> (MEV/MAV/MRV bands for all 18 muscles, editable) — schema v5→v7, 276 tests,
> offline-first, no accounts, no social.
