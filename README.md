# Kinetic v0.1.2

![version](https://img.shields.io/badge/version-0.1.2-22D3A5)
![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![tests](https://img.shields.io/badge/tests-216%20passing-22D3A5)
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
- Next-weight suggestions via double progression with auto-deload
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
- Body heat map: red → grey over 48–72 h since a muscle was trained
- Exercise progress screen: e1RM/volume trend, all-time PRs,
  last-vs-previous session deltas

### Data
- Full JSON backup (profile, exercises + muscle maps, routines,
  workouts + sets) and CSV export of every set, via the OS share sheet
- JSON import replaces all local data (older backups normalize
  automatically on the way in)
- Optional Supabase sync: pull→push with per-row last-write-wins,
  tombstones, and children riding parents (offline-tested with a fake
  transport; the Supabase project is not live yet — see roadmap)
- Weekly workout reminder notification and a home-screen
  "Start Workout" quick action

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart ^3.13) |
| State | Riverpod 3 (`Notifier` / `AsyncNotifier`) |
| Local DB | Drift (SQLite, WAL) — source of truth, schema v3 |
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
  filled); `supabase/schema.sql` is **not** run until Phase 10.

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
flutter test          # 216 tests
flutter run
```

Release APK (fully local; cloud sync stays "not configured" without
dart-defines):

```bash
flutter build apk --release
```

Optional sync build:

```bash
flutter build apk \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key>
```

## Project structure

```text
lib/
  main.dart                  boot order: DB → seed → prefs → optional Supabase
  app.dart                   router, 4-tab shell, frosted-glass drawer
  core/
    database/                Drift schema (v3, 13 tables) + seed service
    settings/                units, theme, plates, rest tiers (SharedPreferences)
    sync/                    pull→push engine (LWW, tombstones, fake transport)
    theme/                   dark-first design tokens, grade/heat colors
    export/                  JSON/CSV backup builders + share sheet
    utils/                   plate calculator, rest formatting
  features/
    home/                    start workout + stat cards
    routines/                library, builder, weekly plan, progress
    workout/                 live logger, session notifier, rest resolver
    analytics/               charts, rollups, grade engine, heat map
    profile/                 profile, data management, privacy
    settings/                settings page + sync section
supabase/schema.sql          remote DDL (not applied until Phase 10)
assets/seed/                 19 muscle groups, 89 exercises
```
<<<<<<< HEAD
=======

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

## Roadmap

- **Phase 9** home-screen widget + volume landmarks
- **Phase 10** end-to-end encrypted sync — `schema.sql` must not be
  applied to the Supabase project before this lands

## License

<<<<<<< HEAD
This repository does not currently include a LICENSE file. Before publicly distributing or publishing the project, add an appropriate open source license.

## Summary

Kinetic is built for people who care about performance, consistency, and ownership of their training data. It combines the speed and flexibility of local-first mobile tooling with the power of modern analytics and optional cloud sync.

Whether you are tracking a simple home workout or managing long-term training progress, Kinetic is designed to be dependable, accurate, and focused on the work that matters.
>>>>>>> 76f4f9d (README: resolve committed merge-conflict markers; document Round 4)
=======
MIT — see [LICENSE](LICENSE).
>>>>>>> 6bfc444 (frosted-glass drawer — blur + token tint, tab shortcuts, Start Workout / Exercise Library)
