# Kinetic

Kinetic is a private, offline-first strength training tracker built with Flutter and Dart. It helps athletes plan routines, log workouts, monitor progress, and analyze training trends without depending on a constant internet connection.

The app is designed around a simple principle: your training data belongs to you. It stores the source of truth locally, supports optional cloud sync, and keeps the experience fast, reliable, and usable even when you are offline.

## Why Kinetic

Most strength apps are optimized for social features, feeds, or subscriptions. Kinetic focuses on the essentials:

- Fast workout logging
- Offline-first operation
- Accurate performance analytics
- Flexible routine building
- Privacy-conscious local storage
- Optional cloud backup and sync

## Key Features

### Workout tracking
- Log sets, reps, weight, RPE, rest time, and notes
- Track supersets and workout flow in real time
- Use a built-in plate calculator for efficient loading
- Capture next-weight suggestions based on training progress

### Routine management
- Build and manage custom training routines
- Organize exercises by target muscle groups and movement patterns
- Create warm-ups and structured workout sessions
- Maintain a personal exercise library tailored to your goals

### Analytics and progress
- Monitor volume, strength trends, and personal records
- Review performance over rolling windows and custom time ranges
- Inspect muscle-level progress with grade-based analytics
- Visualize workout history with charts and summary data

### Offline-first architecture
- Store core workout data in a local SQLite database
- Keep the app fully functional without network access
- Use a sync engine to reconcile local and remote data safely

### Cloud sync and export
- Optional Supabase integration for authentication and data sync
- Per-user row-level access controls in the remote schema
- Export workout data as JSON and CSV for backup or reporting
- Share data through the device share sheet

## Tech Stack

- Flutter + Dart
- Riverpod for state management
- Drift + SQLite for the local database
- Supabase for optional cloud authentication and sync
- go_router for navigation
- fl_chart for analytics visualization
- SharedPreferences for lightweight app preferences
- Flutter local notifications for reminders
- Lottie for animations

## Architecture Overview

Kinetic follows a layered architecture with local-first data ownership at its center.

```text
UI / Screens
  ↓
Riverpod providers and controllers
  ↓
Repository and service layer
  ↓
Local Drift database (source of truth)
  ↓
Optional Supabase sync layer
```

The application intentionally treats the local database as the authoritative state. Remote cloud storage is used as a synchronization mechanism, not as the primary source of truth.

## Project Structure

```text
kinetic/
├── android/                     Android app configuration
├── ios/                         iOS app configuration
├── assets/
│   ├── anim/                   Lottie animation assets
│   └── seed/                   Seed data for exercises and muscle groups
├── lib/
│   ├── app.dart                 App shell and app configuration
│   ├── main.dart               App bootstrap and initialization
│   ├── core/
│   │   ├── database/           Drift schemas and database setup
│   │   ├── settings/           Preferences and user settings
│   │   ├── sync/               Sync logic and connectivity flow
│   │   ├── theme/              App theme and design tokens
│   │   ├── export/             Backup and export services
│   │   └── utils/              Helper logic such as plate calculation
│   └── features/
│       ├── analytics/          Analytics, charts, and training insights
│       ├── home/               Home dashboard and workout entry points
│       ├── profile/            Settings, sync, auth, and export tools
│       ├── routines/           Routine building and exercise planning
│       └── workout/            Workout logging and exercise tracking
├── supabase/
│   └── schema.sql              Remote database schema for Supabase
├── test/                       Automated tests
├── analysis_options.yaml       Linting and analysis rules
├── pubspec.yaml                Flutter package configuration
├── .gitignore
├── README.md
└── flutter_launcher_icons.yaml
```

## Getting Started

### Prerequisites

Before running the app, install:

- Flutter SDK 3.13+
- Dart SDK 3.13+
- Android Studio or VS Code with Flutter plugins
- An emulator or physical device

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Run tests

```bash
flutter test
```

### Analyze the project

```bash
flutter analyze
```

## Supabase Setup (Optional)

Kinetic supports cloud sync through Supabase. To enable it:

1. Create a Supabase project
2. Apply the schema located in `supabase/schema.sql`
3. Add your project URL and anonymous key as Dart defines

```bash
flutter build apk \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key>
```

Without these values, the app continues to work in a fully local mode and will display cloud sync as unavailable.

## Data Model and Privacy

Kinetic is designed with a privacy-first approach:

- Workout data is stored locally in SQLite
- Sync is optional and user-scoped
- Cloud access is controlled with row-level security
- Training information remains under the user's control
- Data can be exported in portable formats for backup or migration

## Development Notes

This project uses generated code and schema-driven local persistence. If you change the database schema, regenerate the Drift code as needed:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Roadmap

The project already includes a wide range of strength-focused functionality, including:

- Workout logging and exercise tracking
- Routine management
- Analytics and charting
- Muscle grade modeling
- Export and backup tools
- Local-first sync infrastructure
- Optional Supabase integration

Future work includes broader smart-training features, deeper device integration, and additional automation for reminders and training guidance.

## Contributing

Contributions are welcome. If you plan to improve the app, follow the repository workflow and keep changes focused, testable, and aligned with the app’s local-first design principles.

## License

This repository does not currently include a LICENSE file. Before publicly distributing or publishing the project, add an appropriate open source license.

## Summary

Kinetic is built for people who care about performance, consistency, and ownership of their training data. It combines the speed and flexibility of local-first mobile tooling with the power of modern analytics and optional cloud sync.

Whether you are tracking a simple home workout or managing long-term training progress, Kinetic is designed to be dependable, accurate, and focused on the work that matters.
