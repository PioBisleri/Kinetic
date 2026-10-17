# Kinetic

![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![tests](https://img.shields.io/badge/tests-343%20passing-22D3A5)
![Android](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A private, offline-first strength training tracker for Android. Log
workouts, build routines, and watch your progress — no feed, no
followers, no subscriptions. Your data lives on your device; the local
database is always the source of truth.

## Highlights

- **Offline-first** — every feature works with no network. Sync is
  optional and, when configured, reconciles against your own project.
- **Fast logging** — sets, reps, weight, RPE, notes, supersets, and a
  rest timer that starts itself; plate calculator and next-weight
  suggestions built into the set editor.
- **Serious routines** — drag-and-drop builder with per-entry set types
  (warm-up / working / drop / failure) and per-exercise rest overrides.
- **Muscle-level analytics** — volume, 1RM progression, consistency
  calendar, a body heat map, and the F–S Muscle Grade per muscle.
- **Private by design** — no social features exist in the codebase.
  Export JSON/CSV backups yourself; delete anything, any time.

## Features

### Workout logging
- Live logger with set editor (weight, reps, RPE, notes), supersets,
  cardio distance/duration steppers, and per-set rest timers
- Rest timer auto-starts after each completed set; duration comes from
  the routine entry → exercise → app default chain (see *Rest system*)
- Plate calculator (kg or lb plates, optional micro-loading plates)
- Next-weight suggestions via double progression with auto-deload;
  the step is per-exercise (load increment override or inherit)
- Finish/discard flow with confirmation; in-progress workouts resume
  after a restart

### Routines & planning
- Routine builder: drag-and-drop ordering, target sets × reps, notes
- **Custom set types per entry** — warm-up / drop / failure steppers
  with the working sets derived from the total (enter 5 sets + 1
  warm-up + 1 failure → 3 working)
- Per-exercise rest override ("Default" chip ⇄ seconds) and a
  per-routine rest override on every entry
- View-only weekly plan (`/schedule`) assigning routines to days
- Exercise library with ranked smart search (typos, synonyms, muscle
  names) and custom exercises (muscle map, contribution weights)

### Rest system (v0.1.1)
Three tiers, resolved routine → exercise → app settings:

| Tier | Where | Default |
|---|---|---|
| Per-type app defaults | Settings → Rest | warm-up 60 s · working 90 s · failure 120 s (each editable, 0 = Off) |
| Per-exercise | Exercise editor → Rest between sets | inherits the app default |
| Per-routine | Routine editor → rest control on an entry | overrides both |

### Analytics
- Weekly volume and 1RM progression charts, consistency calendar
- **Muscle Grade** (F–S) per muscle and muscle balance ratios
- **Volume landmarks** — MEV / MAV / MRV sets-per-week bands per muscle
  on a color-graded track (editable per muscle, curated defaults)
- Body heat map: red → grey over 48–72 h since a muscle was trained
- Exercise progress screen: e1RM/volume trend, all-time PRs,
  last-vs-previous session deltas

### Health & Diet (schema v9)
- Diet page (`/diet`): manual daily macro logging (kcal, protein,
  carbs, fat) with reusable per-serving custom foods (name, brand,
  serving size in g/ml/pieces)
- Quick-log water (+100/250/500 ml), a daily step card and macro card —
  steps from the phone's step sensor (15 s batched writes)
- **Live activity notification** (v0.1.5): a persistent, low-priority
  notification keeping today's steps, burned kcal and water while the
  app is closed, powered by a foreground health-type step service;
  survives swipe-away and reboot, off by default
- **Workout detail** (`/workout-history/:id`, v0.1.5): tap a home
  history tile for the full set list — per-set type badges (W/D/F),
  completed set count and total volume
- Everything rides one daily `body_metrics` row per metric day —
  weigh-ins, water and steps merge instead of clobbering each other
- Hourly hydrate reminders inside a configurable window
  (Settings → Nutrition & Health; one stable alarm per slot, narrowed
  windows leave no orphan alarms)

### Data
- **Your data** profile: name, height (cm or ft/in), date of birth, sex,
  body fat %, training goal, bodyweight — plus a derived BMI row
  (display-only; the grade math never sees them) and a weigh-in log
  with a 12-week bodyweight trend
- Full JSON backup (profile, exercises + muscle maps, routines,
  workouts + sets, weigh-ins, landmark overrides, food library + food
  logs) and CSV export of every set, via the OS share sheet
- JSON import replaces all local data (older backups normalize
  automatically on the way in)
- Optional Supabase sync: pull→push with per-row last-write-wins,
  tombstones, and children riding parents (offline-tested with a fake
  transport)
- **Encryption** (wired in v0.1.5): sync payloads are AES-256-GCM
  encrypted; keys are derived on-device via Argon2id from a passphrase
  that never leaves it — the server sees only ciphertext, and a peer
  row that can't be decrypted is rejected instead of silently dropped
- Weekly workout reminder notification and a home-screen
  "Start Workout" quick action
- Home-screen widget: this week's volume, streak and next-up routine —
  tap it to boot (or resume) straight into the logger

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart ^3.13) |
| State | Riverpod 3 (`Notifier` / `AsyncNotifier`) |
| Local DB | Drift (SQLite, WAL) — source of truth, schema v9 |
| Cloud | Supabase (optional; RLS-locked per user) |
| Routing | go_router — 4-tab stateful shell + pushed routes |
| Charts | fl_chart |
| Prefs | SharedPreferences |

## Architecture

```text
UI (Riverpod consumers)
  → Controllers / Notifiers (live session, rest timer, grade engine)
    → Repository / service layer
      ├─ Drift/SQLite   ← LOCAL SOURCE OF TRUTH (always wins)
      └─ Supabase sync  ← pull→push, per-row last-write-wins (optional)
```

Rules:

- UUIDs are generated client-side; mutable tables carry
  `updated_at / synced_at / deleted_at` (tombstone).
- The network is never a precondition for logging a set.
- All weights are stored in **kg**; lbs is display-only.
- The exercise catalog is seeded from bundled JSON — usable on a plane.
- Schema changes migrate in code via Drift's gated `onUpgrade`
  (`schemaVersion` 3 → warm-up/drop/failure counts + rest columns back
  filled); `supabase/schema.sql` is **not** run until the Supabase
  project goes live.

## Muscle Grade

Per muscle, rolling 30-day window:

```text
score = 0.40·volume + 0.40·strength + 0.20·consistency     (0–100)

volume       = 100·ln(1 + V/1000) / ln(1 + target/1000)   target = 8000 kg/wk × 4.33
strength     = 100·(e1RM / (BW × standard))^0.8            Epley: w·(1 + reps/30)
consistency  = 100·(days/target)·(0.6 + 0.4·freshness)    freshness fades over 72 h

S ≥ 90 · A ≥ 78 · B ≥ 64 · C ≥ 48 · D ≥ 30 · F < 30
```

Volume is attributed per muscle via `exercise_muscle_map.contribution`
(bench: chest 1.0, triceps 0.5, front delts 0.4). The same freshness
term drives the body heat map.

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after schema edits
flutter analyze
flutter test          # 340 tests
flutter run
```

Release APK (fully local; cloud sync stays "not configured" without
dart-defines):

```bash
./build-apk.sh            # -> kinetic-v<version>.apk in the repo root
```

The script runs `flutter build apk --release` (with the offline-safe
`--no-version-check`) and copies the result to a file named after the
pubspec version. Extra arguments pass straight through, so an optional
sync build is:

```bash
./build-apk.sh \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key>
```

Either way the raw artifact also stays at
`build/app/outputs/flutter-apk/app-release.apk`.

Two pub dependencies are **vendored** under `dependencies/` with
Android Gradle Plugin 9 compatibility patches (registered as
`dependency_overrides` in `pubspec.yaml`; each vendored `build.gradle`
documents what changed and how to re-apply it after refreshing):

- `pedometer` — AGP 9 removed the `kotlin-android` plugin and the old
  android DSL upstream still uses.
- `permission_handler_android` — caps its code at platform 36 (its
  `ACCESS_LOCAL_NETWORK` bits are API-37 symbols that older local
  SDKs do not ship).

Drop both overrides when upstream ships fixed versions.

## Project structure

```text
lib/
  main.dart                  boot order: DB → seed → prefs → optional Supabase
  app.dart                   router, 4-tab shell, frosted-glass drawer
  core/
    database/                Drift schema (v9, 17 tables) + seed service
    settings/                units, theme, plates, rest tiers (SharedPreferences)
    sync/                    pull→push engine (LWW, tombstones, fake transport)
    theme/                   dark-first design tokens, grade/heat colors
    export/                  JSON/CSV backup builders + share sheet
    utils/                   plate calculator, rest formatting
  features/
    home/                    start workout, stat cards, home-widget stats
    routines/                library, builder, weekly plan, progress
    workout/                 live logger, session notifier, rest resolver
    analytics/               charts, rollups, grade engine, heat map
    profile/                 profile, data management, privacy
    settings/                settings page + sync section
supabase/schema.sql          remote DDL (encrypted sync ready; not yet
                             applied to a live project)
assets/seed/                 19 muscle groups, 89 exercises
```

## Delivery history

- **Phase 1 ✅** foundation, schema, seed catalog, shell, grade/plate engines
- **Phase 2 ✅** live workout logger (sets, RPE, rest timer, plate UI,
  supersets, notes)
- **Phase 3 ✅** routine builder (drag-and-drop, targets, per-type set
  counts — warm-up/working/drop/failure)
- **Phase 4 ✅** analytics & charts (volume, 1RM, calendar, rollups)
- **Phase 5 ✅** body heat map + Muscle Grade dashboard + bodyweight input
- **Phase 6 ✅** exercise animations + custom exercises (create/edit,
  muscle map, tombstone delete)
- **Phase 7 ✅** Supabase sync engine (auth, pull→push LWW, tombstones,
  offline-tested) + export + light theme
- **Phase 8 ✅** smart logging (next-weight suggestions, exercise
  progress), AMOLED mode, quick action, weekly reminders
- **Round 2 ✅** UX pass — left drawer + Settings page, smart search,
  weekly plan (schema v2), ultra-flat hairline design
- **Round 3 ✅ (v0.1.1)** custom set types per routine entry + three-tier
  rest system (schema v3)
- **Round 4 ✅ (v0.1.2)** frosted-glass drawer — translucent blur over
  the active tab, tab shortcuts, Start Workout / Exercise Library entries
- **Round 5 ✅ (v0.1.3)** profile "Your data" + BMI (schema v4), algorithm
  transparency (grade breakdowns, how-grades/suggestion sheets), GitHub
  Actions CI, home-screen widget
- **Round 6 ✅ (v0.1.4)** per-exercise progression increments (schema v5),
  bodyweight trend (schema v6), volume landmarks card (schema v7)
- **Round 7 ✅ (folded into v0.1.5)** Nix dev shell (Flutter 3.47.5 +
  Android SDK via flake), KGP warning resolved (`builtInKotlin=true`),
  schema v8 (dropped dead `sync_queue` table), UX polish round,
  encrypted-sync core built (Argon2id + AES-256-GCM, offline-tested;
  boot-time wiring still pending)
- **Round 8 ✅ (v0.1.5)** Health & diet — macro logging + custom food
  library, water quick-log, pedometer steps (all on schema v9's
  daily-metric row), water-reminder window, AGP 9 fixes for two
  vendored plugins
- **Round 9 ✅ (v0.1.5)** Device-feedback pass — sync encryption is now
  wired into the live path (pushes format-2 ciphertext; rejecting
  undecryptable rows), a background **Live activity notification**
  (steps + burned kcal + hydration, survives swipe-away and reboot), a
  **workout detail page** from history, a diet-page steps card and
  large-font header fixes, plus UI-polish foundations (shared
  theme/text idioms, confirm-dialog & sheet & empty-state widgets)
- **Round 9.1/9.2 ✅ (v0.1.5, rebaked)** Notification keystones fixed
  from device logs (UPDATE-start FGS crash, stuck placeholder via
  type-safe pref reads, `specialUse` foreground service + battery
  optimization exemption + orphan cleanup), and a UX upgrade — Profile
  and Settings tabs redesigned (hero header, Body/Stats cards,
  icon-headed sections), a theme system (**Auto/Light/Dark** + **accent
  palette** swatches + reset-to-default), and Sync settings only shown
  when sync is built in

## Roadmap

- **Encrypted sync** — wired end-to-end in v0.1.5 (format-2 ciphertext
  + rejection of undecryptable rows); remaining: bring the Supabase
  project up (apply `schema.sql`) and on-device verification

## License

MIT — see [LICENSE](LICENSE).
