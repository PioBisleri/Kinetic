# Kinetic — Build Handoff & Progress Log

> Offline-first fitness tracker (Hevy-like), personal analytics only — **no social
> features, ever**. This file exists so the project can move to another machine
> without losing context. Last updated: **2026-10-17**, at **v0.1.5+5**,
> schema **v9**, **343 tests green**, all CI runs **passing**.

---

## 1. Where things stand right now

| Item | State |
|---|---|
| Version | `0.1.5+5` (`pubspec.yaml`) |
| DB schema | **v9** (`AppDatabase.schemaVersion`) |
| Tests | **343 passing**, 55 test files, `flutter analyze` clean |
| Repo | `main` @ `9e33586`, Rounds 9 / 9.1 / 9.2 changes **uncommitted** |
| Remote | `origin` = `git@github.com:PioBisleri/Kinetic.git` (public) |
| Pushed | everything **through `9e33586`** (this handoff doc) |
| CI | GitHub Actions `CI` — all runs `conclusion: success` (analyze + test on Flutter 3.47.5) |
| Supabase | **project NOT live**, `supabase/schema.sql` **never applied** — encryption now wired end-to-end (v0.1.5, §9A) but unverified against a real server |
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
supabase/schema.sql              # remote DDL — NOT applied (project not live)
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
| 9 | daily health + nutrition: `body_metrics` gains nullable `water_ml`/`steps` (plain ALTER, no backfill); new `foods` + `food_logs` tables | create/additive only; `addColumnIfAbsent` guards the v≤5→v9 replay (the v6 branch creates the table from the *current* column set) |

Tables (17): `profiles, body_metrics, volume_landmarks, muscle_groups, exercises,
exercise_muscle_map, routines, routine_exercises, weekly_plans, workouts,
workout_sets, muscle_volume_daily, exercise_history, muscle_grade_history,
foods, food_logs`.

**Migration rules**

- All schema changes live in code via Drift's gated `onUpgrade` — migrations are
  **never** applied via SQL file.
- Each new version = one `if (from < N)` branch, and older tests
  (`v1 → N`) must replay every earlier branch.
- After a partial `onUpgrade(from, to)` with `to < schemaVersion`, drift reads of
  not-yet-altered tables fail — use raw SQL in migration tests, or run to current.
- **After any schema edit:** run build_runner (§3) and add a migration test.

**`supabase/schema.sql`** holds the 10 **synced** tables (profiles, exercises,
exercise_muscle_map, routines, routine_exercises, workouts, workout_sets,
body_metrics, foods, food_logs). **Local-only** and therefore intentionally
absent: `weekly_plans`, `volume_landmarks` (plus rollups and the seeded
muscle_groups).
It must **not** be applied to the Supabase project before the project
goes live (Phase 10's encryption is already built — see §10).

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

**Round 7 — v0.1.5 (complete):**
- **7A** — Nix dev shell (`flake.nix` + `direnv`): Flutter 3.47.5, Android SDK
  (platforms 35/36, build-tools 36.0.0, NDK 28.2.13676358, cmake 3.22.1), JDK 17,
  sqlite3. Pinned to nixpkgs PR #567033 head until 3.47.5 lands in nixos-unstable.
- **7B** — KGP warning resolved: `android.builtInKotlin=true` (both plugins already
  gate on it). Flutter CLI warning is a false positive (static scan).
- **7C** — schema v8: dropped never-used `sync_queue` table (16 → 15 tables).
  Migration test added.
- **7D** — UX polish: PopScope unsaved-changes guard (routine + exercise editors),
  remove-from-workout confirmation, Home "Start from routine" sheet, haptic +
  undo snackbar, profile errorText on invalid input, stepper hit targets 34→44px,
  add-exercise autofocus + "Create" row.
- **7E** — Phase 10 encryption: `cryptography` package, Argon2id key derivation,
  AES-256-GCM payload encryption at `SyncCodec.encode/decode`, format column
  handling, `minSyncVersion = 24`, key setup UI in Settings. 284 tests green.
  (Runtime wiring gap discovered later — see §10; **closed in v0.1.5**,
  §6 Round 9 / 9A.)
- **7F** — de-versioning pass: version display removed everywhere (drawer
  footer, profile subtitle, README title badge); version lives only in
  `pubspec.yaml` for the APK filename and §9.7 rewritten accordingly.

**Round 8 — Health & diet (v0.1.5, folded with Round 7 into one release):**
- **8A** — schema v9: `body_metrics` gains nullable `water_ml` + `steps`
  (one daily row per metric day; weigh-in/water/steps writers merge, never
  clobber); new `foods` (custom per-serving food library) + `food_logs`
  (denormalized per-serving snapshots, tombstoned like everything else).
- **8B** — diet feature: `/diet` route + drawer entry + Home `_TodayStrip`
  chips (water/steps/kcal-left). Macro totals sum the day's snapshots;
  `ManualLogSheet` stores Atwater kcal for manual entries;
  `FoodPickerSheet` re-uses smart_search; library tile tap = log one
  serving; delete + undo snackbar everywhere.
- **8C** — water reminders: `WaterReminderService` (weekly-reminder mirror)
  with one stable-id alarm per hourly slot in a start..end window
  (`Settings → Nutrition & Health`); `end < start` degenerates to a single
  daily alarm.
- **8D** — steps: `pedometer` + `permission_handler` (`ACTIVITY_RECOGNITION`
  runtime permission); `StepMath.absorb` handles day rollover (fixed order:
  rollover wins over reboot) and device reboots; 15 s batched writes;
  guard-never-throw like the notification services.
- **8E** — new Settings fields with sane defaults (kcal 2500, P 150, C 250,
  F 70, water 2500 ml, steps 8000, reminders off, window 9–22 @60 min).
- **8F** — sync/export: foods + food_logs pulled/pushed (`SyncEngine`,
  transport table order, `filterColumns`); export `foods`/`foodLogs` keys;
  import accepts older backups without them; `deleteAllData` wipes them.
  Also fixed two pre-existing wrong wire-table tags (`exercise_muscle_map`
  ↔ `body_metrics` swapped in the push code) and restored the v3
  `routine_exercises` set-type columns missing from `schema.sql`.
- **8G** — AGP 9 fixes for two vendored plugins under `dependencies/`
  (`dependency_overrides`): `pedometer` (drop kotlin-android apply, modern
  android DSL) and `permission_handler_android` (compileSdk 36 + literal
  stubs for the API-37 `ACCESS_LOCAL_NETWORK` constants; the local SDK
  stops at platform 36). Each vendored build file documents how to re-apply
  after refreshing upstream; drop the overrides when upstream fixes ship.
- **8H** — test suite 278 → 318: migration (v8→9 + v1→9 replay), food_math,
  StepMath, windowSlots, sync round-trips (incl. water/steps-only days),
  export/import/delete round-trips, `/diet` widget tests; settings/pushed
  widget suites widened (2000px viewport) for the taller Settings page and
  extra drawer tile.

**Round 9 — device-feedback round (v0.1.5):**
- **9A — sync encryption wired (the §10 gap is closed).** `SyncCodec`
  gained `static void apply(SecretKey?)`; the epoch-keyed
  `syncEncryptionKeyProvider` derives the key once per passphrase
  change (passphrase is the single source of truth, restored from
  prefs on boot), and `SyncController.syncNow()` runs
  `SyncCodec.apply(key)` before `engine.sync()`. The settings handlers
  (enable / rotate / reset) bump the epoch instead of nulling the codec
  in place. Previously the app synced plaintext even with a passphrase
  set (enabled flag was memory-only and the key provider was never
  assigned). `SyncCodec.decode` now `FormatException`s on a format-2
  row when no key is active ("encrypted sync payload but no sync
  passphrase is set") instead of silently returning null.
  `test/sync_encryption_wiring_test.dart` — 5 tests: cipher
  round-trip on push (format 2), second-session decrypt, decode
  refusal, rotate-bump, plaintext fallback without passphrase.
- **9B — live activity notification** (the "close the app, tracking
  disappears" complaint). A `foregroundServiceType="health"`
  `KineticLiveService` owns `TYPE_STEP_COUNTER` absorb (day-rollover
  beats reboot; shrinking counter ⇒ sensor reboot) via its own
  `SensorEventListener`, with everything it needs read from the
  prefs file bridge (`live_config` JSON, targets, last
  bodyweight, `live_enabled`). The ongoing notification (low-priority
  `Notification.Builder` — no androidx.core dependency, channel
  `live_activity`, id 0x2162 past the other FLT bases) shows
  steps / burned kcal (`kg × steps × 0.762/1000 × 1.036`) /
  today's water per the three toggles, and its UPDATE/STOP actions
  re-notify without waking the app. `KineticLiveBootReceiver`
  restarts it on `BOOT_COMPLETED` / `MY_PACKAGE_REPLACED` /
  quickboot when last-on. Dart side
  (`live_activity_service.dart`) applies config, reconciles on app
  start and every resume (`adoptNativeSteps` mirrors `StepMath.absorb`
  into `body_metrics`), and refreshes after every water / food /
  weigh-in log and target change. Toggle + three checkboxes live in
  Settings → Nutrition & Health (POST_NOTIFICATIONS gate on 13+).
- **9C — diet page feedback fixes.** The four problems from the device
  video, diet side: a read-only `STEPS` card (today vs `stepsTarget`
  target with the accent progress bar) now sits above the water card;
  the "Today's food" / "My foods" header rows lost their wide label
  buttons for icon-only add buttons (the old full-text `FilledButton`
  crushed the title into a vertical letter stack at large font scale —
  regression-tested at textScale 2.0); and the food library shows a
  spinner while loading instead of blank space. Header button keys
  `diet-log-food` / `diet-new-food` are unchanged.
- **9D — workout history detail page.** Home's recent-workout tiles now
  open `/workout-history/:id`: `WorkoutDetail` (FutureProvider.family)
  groups the workout's sets per exercise (exercises come by name,
  un-planned rows too) with per-set type badges (W/D/F), per-row RPE
  and dimmed uncompleted sets, plus a header with date, duration and a
  totals container over all completed sets (count) and completed hard
  sets (volume kg). Long-press delete is unchanged.

**Round 9.1 — device-feedback fixes (same 0.1.5+5 build, rebaked):**
- **9E — live-notification crash loop (verified on the Android 16
  device via `logcat -b crash`).** Chain: `MainActivity.startLiveService`
  → `startForegroundService()` → service `onCreate` → typed
  `startForeground(id, n, TYPE_HEALTH)` threw (health type requires
  ACTIVITY_RECOGNITION while-in-use) → the catch swallowed it and
  `stopSelf()` ran **before the FGS contract was satisfied** → the
  system killed the process (`ForegroundServiceDidNotStartInTimeException`);
  since `live_enabled` is persisted before the start attempt, every
  app open repeated this. Fixes, in three layers (defense in depth):
  (1) `KineticLiveService.onCreate` satisfies the contract FIRST — a
  guaranteed-buildable placeholder notification, typed `startForeground`
  → on any Throwable falls back to the plain 2-arg call (type-NONE FGS
  is always permitted) → only the registered sensor or display the real
  content; failures after the contract do a legal
  `stopForeground(REMOVE)` + `stopSelf()`, and a `failed` flag makes
  `onStartCommand` return `START_NOT_STICKY`. (2) `MainActivity`
  soft-fails: no `startForegroundService` at all while ACTIVITY_RECOGNITION
  is revoked (starts permitted Q+) — the notification just never comes on.
  (3) The settings toggle additionally requests
  `Permission.activityRecognition` beside the notification ask.
  Service catches log under the `KineticLive` tag.
- **9F — undo snacks never auto-dismissed.** Flutter 3.38 changed the
  contract: SnackBars with an action default `persist: null` = never
  auto-dismisses (reported as "the undo option persists and just
  doesn't go away"). Every snack in the app is a quick undo, so all
  three construction sites set `persist: false`: the shared `showSnack`
  helper (covers the set-logged undo), and the two inline snacks in
  `diet_page.dart` (water +N, food-log remove). Non-action snacks were
  unaffected. `diet_page_test` also asserts `SnackBar.persist == false`.
- **9G — water card redesigned (user picked the segmented control
  flavor).** One `SegmentedButton` (+100 / +250 / +500
  segments, `emptySelectionAllowed`, `showSelectedIcon: false`) replaces
  the three wide tonal buttons; the bar thickens 6→8 px with a droplet
  icon and an auto-computed percent to the right (clamped 0–999). The
  `diet-water-scale` key survived; segment taps are found by text in
  tests.
- **9H — live-notification quality (device logs drove every fix):**
  * UPDATE-start crash loop, part 2: the 21:27/21:28 re-crashes on the
    9E build proved each `startForegroundService()` call owes its own
    (time-limited) `startForeground()` — including calls that land on an
    *already-running* service. The Dart `update` path (reconcile, refresh)
    start-bombed the running service without promoting. Now
    `onStartCommand` re-runs `promote()` (idempotent) on every non-stop
    start; `promote()` is extracted (typed specialUse → untyped →
    `failed`, same defense as 9E).
  * Stuck "Tracking your day" placeholder: native `getFloat/getInt` on
    Dart-written prefs threw ClassCastException (shared_preferences
    stores doubles as raw long bits) inside `buildNotification`'s catch —
    real content never posted. All Dart-written values now read via
    `prefs.all[key] as? Number` coercion (`numPref`/`intPref`);
    verified on-device: notification renders "Steps N / target" + water.
  * "Turns off after a while / swipable": the `health` FGS type is a
    *while-in-use* type — `Stopping service due to app idle` after ~70 s
    of backgrounding, leaving a marker-stripped swipeable orphan.
    Manifest type switched to `specialUse` (+ `PROPERTY_SPECIAL_USE_FGS_SUBTYPE`
    value + `FOREGROUND_SERVICE_SPECIAL_USE` permission). Orphans are
    also cancelled in `onDestroy` (the system-stop path never reaches
    `stopForeground`).
  * OEM power-manager reality: even a specialUse service is stopped
    "due to app idle" unless the app is exempt from battery
    optimization (verified on the Samsung; `dumpsys deviceidle`
    whitelist was empty). Added the exemption flow: manifest
    `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, MainActivity
    `battery-exemption` / `request-battery-exemption` channel methods
    (direct dialog → optimization-list fallback), Dart glue on
    `LiveActivity`, and a "Run in background" status row in the Live
    activity card (re-checks on lifecycle resume).
  * `registerListener fail (2)` was diagnosed as Samsung noise for
    re-registering the same listener (`dumpsys sensorservice` showed
    `result=OK` each time); `registerSensor()` now registers exactly
    once (`registered` flag) and falls back `SENSOR_DELAY_UI` →
    `SENSOR_DELAY_FASTEST`.
- **9I — Tabs redesign (user: "profile and settings look very ugly")**
  plus conditional sync + theming:
  * Settings restructured into icon-headed cards: Units → Appearance
    → Sync → Reminders → Nutrition & Health → Live activity → Rest.
  * Appearance (Round 9.2): `ThemeMode` Auto/Light/Dark
    `SegmentedButton` ('theme-mode-segments'; `system` + `light`
    persisted as `'theme' = system|light|dark`, dark stays shipped
    default), **AMOLED black** stays a dark-only toggle, **accent
    palette** — 8 curated `AppAccent` palettes ('kinetic' default) as
    `accent-<id>` swatch keys re-seeding `ColorScheme.fromSeed`
    app-wide, and a **Reset to default** row (confirm → dark · AMOLED
    off · kinetic).
  * Accent went dynamic: `AppTheme.dark/light()` take a seed
    (`onAccent()` picks dark/white ink by luminance); all ~70
    `AppColors.accent` call-sites migrated to `context.accent` /
    `context.accentDim` (new `AppColorsContext` getters). Light getter
    became `AppTheme.light()`.
  * Sync section is now **conditional** (user decision): shown only when
    `supabaseConfiguredProvider` is true — a build without the
    Supabase dart-defines shows no sync UI at all.
  * Live activity card gained the battery row above; targets live in
    Nutrition & Health (keys `target-*` unchanged).
  * Profile redesign (user picked "minimal header + cards"): avatar
    disc + name/goal hero header, `YourDataCard` split into **Body**
    (name/height/dob/sex/body-fat/goal) and **Stats**
    (bodyweight/BMI/trend) cards, danger-zone icons on `context.danger`,
    section icons across Data/Privacy/About. All `profile-*`,
    `bodyweight-input`, export/import/delete keys kept.
  * Tests: widget_test's "sync not configured" assertion flipped to
    expectsNothing (new contract), amoled_theme test drives theme
    segments, your_data_card scroll helper now demands hit-testability,
    new `appearance_palette_test.dart` (swatch → ThemeData, segments,
    reset). 343 tests, analyze clean; APK rebuilt same
    `kinetic-v0.1.5.apk` (0.1.5+5).

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
  It was re-derived and confirmed in Round 7E: `minSyncVersion = 24` lives in
  `sync_engine.dart`.
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

**Suite:** 318 tests / 50 files. Migration tests, widget tests (pump the real
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
8. **Version bump touches 1 place:** `pubspec.yaml`. The version is for
   **releases only** — it is no longer displayed anywhere (README title/badge,
   drawer footer, profile subtitle were de-versioned), and `build-apk.sh` reads
   it solely to name the APK (`kinetic-v<version>.apk`). Plus the tests badge
   and delivery-history line in README when the count/round changes. All README
   badges are **static shields.io images** — edit by hand.

**CI:** `.github/workflows/ci.yml` — `flutter-action@v2` pins **3.47.5**,
installs `libsqlite3-0 libsqlite3-dev`, then `pub get` + `analyze` + `test`.
Triggered on push to main / PR / manual. If you bump the Flutter version
locally, bump CI too.

---

## 10. Sync model & Phase 10 (E2E encrypted sync — wired in v0.1.5)

**Working (offline-tested):** `lib/core/sync/` contains `sync_engine`
(pull→push, `since` cursor + overlap re-read, dirty-scan on
`synced_at IS NULL OR updated_at > synced_at`, per-row LWW), `sync_codec`
(wire format), `sync_encryption` (AES-256-GCM payloads), `sync_key_service`
(Argon2id key derivation), `supabase_transport` / `sync_transport` (fake in
tests). Synced tables: profiles, exercises, exercise_muscle_map, routines,
routine_exercises, workouts, workout_sets, body_metrics, foods, food_logs.
In-progress workouts are not pushed until finished. Deeply tested in
`test/sync_engine_test.dart` (encode/decode, tombstones, LWW both directions,
children ride parents, cursor overlap…).

**Phase 10 — built (Round 7E) + wired (Round 9A); unverified against a
live server, §11/§12:**

- `sync_key_service.dart` — derives a 256-bit AES key from the user's
  passphrase via **Argon2id** (peppered with the user id). The passphrase
  never leaves the device; re-derivation on a new device works with the
  same passphrase (no key storage, no server-side key material).
- `sync_encryption.dart` — **AES-256-GCM** row encryption (96-bit nonces):
  non-filter columns collapse into a base64 `payload` (nonce + ct + tag),
  `filterColumns` (id/updated_at/deleted_at/…, plus `format` set to 2)
  stay queryable for the LWW/cursor queries.
- Wire format: every synced table carries a `format` column
  (`supabase/schema.sql`: 1 = plaintext, 2 = encrypted payload);
  `SyncCodec.encode/decode` is encryption-aware (decode of a format-2 row
  with no active key throws, never returns plaintext).
- Schema-compat floor: `minSyncVersion = 24` (`sync_engine.dart`).
- Passphrase set/import + rotate + reset UI in **Settings → Sync**
  (`settings/sync_section.dart`: `sync-passphrase`, `sync-enable-encryption`,
  `sync-rotate-passphrase`, `sync-reset-encryption`; ≥8 char rule).
- **WIRING (v0.1.5, closed):** `SyncCodec.apply(SecretKey?)`; the epoch-keyed
  `syncEncryptionKeyProvider` re-derives on passphrase changes and restores
  from prefs at boot, and `syncNow()` applies the key before each push.
  Regression-tested in `test/sync_encryption_wiring_test.dart`.

**Remaining for live sync:**

1. ~~Close the wiring gap~~ **done (v0.1.5 §9A)** — a real controller with
   `sync.passphrase` set pushes `format = 2` ciphertext (wiring tests) and
   a decoder without the key refuses it.
2. Deploy the Supabase project and apply `supabase/schema.sql` (10 tables,
   `format` columns included — it has never been applied).
3. Run one real-device E2E sync (two devices or wipe/restore) against the
   live project — first real-world validation of the encryption path.
4. Confirm lost-key recovery UX: passphrase lost ⇒ server data unreadable
   (ciphertext-only); re-derive on the new device with the same passphrase,
   else re-encrypt from local data (fresh passphrase = format bump, older
   server rows below `minSyncVersion` stay ignored).

**Roadmap:** live deployment + on-device sync verification.

---

## 11. Watchlist / tech debt

- ✅ **KGP warning resolved (Round 7):** `android/gradle.properties` now sets
  `android.builtInKotlin=true`. Both plugins (`flutter_timezone` 5.1.0,
  `home_widget` 0.10.0) already gate their legacy KGP apply on this flag, so
  neither applies KGP anymore — verified by a successful release build. The
  Flutter CLI still prints the KGP warning because its static scan doesn't
  understand the plugins' Groovy conditionals; this is a false positive that
  disappears when the plugins drop the legacy code path.
- **Two vendored plugin overrides (Round 8):** `pedometer` and
  `permission_handler_android` under `dependencies/` carry AGP 9
  compatibility patches (see `pubspec.yaml` comment). Upstream has no AGP-9
  fix yet (pedometer 4.2.0 is the latest release; permission_handler 13.x
  forces the 14.x android subpackage). Drop the overrides when upstream
  ships fixed versions, and re-run `./build-apk.sh` to confirm.
- Network on the build machine has been flaky historically (git fetches
  hanging); the CLI flag and CI are the workarounds.
- 15 packages have newer (non-breaking-constraint) versions —
  `flutter pub outdated` when convenient; none urgent.
- On-device UI checks always fall to human eyes — install and click through
  after each round.

---

## 12. Release checklist (as done for v0.1.4)

1. All phases of the round committed; full suite green (276+), analyze clean.
2. Bump version in `pubspec.yaml` (§9.7 — single place, release-only), tag
   delivery-history line in README.
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
