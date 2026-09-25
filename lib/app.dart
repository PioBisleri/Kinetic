import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_actions/quick_actions.dart';

import 'core/notifications/weekly_reminder_service.dart';
import 'core/settings/settings.dart';
import 'core/sync/sync_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/analytics/analytics_page.dart';
import 'features/home/home_page.dart';
import 'features/profile/profile_page.dart';
import 'features/routines/exercise_detail_page.dart';
import 'features/routines/exercise_edit_page.dart';
import 'features/routines/exercise_library_page.dart';
import 'features/routines/routine_editor_page.dart';
import 'features/routines/routines_page.dart';
import 'features/workout/application/workout_session_notifier.dart';
import 'features/workout/live_workout_page.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Full-screen live logger — pushed over the shell, so no bottom nav.
      GoRoute(
        path: '/workout',
        builder: (context, state) => const LiveWorkoutPage(),
      ),
      // Exercise catalog browser — also full-screen.
      GoRoute(
        path: '/library',
        builder: (context, state) => const ExerciseLibraryPage(),
      ),
      // Custom exercise create/edit ('new' before ':id' to match first).
      GoRoute(
        path: '/library/new',
        builder: (context, state) => const ExerciseEditPage(),
      ),
      GoRoute(
        path: '/library/:id/edit',
        builder: (context, state) => ExerciseEditPage(
          exerciseId: state.pathParameters['id'],
        ),
      ),
      // Exercise detail: animation + weighted muscle metadata.
      GoRoute(
        path: '/library/:id',
        builder: (context, state) =>
            ExerciseDetailPage(exerciseId: state.pathParameters['id']!),
      ),
      // Routine builder routes ('new' must precede ':id' to match first).
      GoRoute(
        path: '/routines/new',
        builder: (context, state) => const RoutineEditorPage(),
      ),
      GoRoute(
        path: '/routines/:id',
        builder: (context, state) =>
            RoutineEditorPage(routineId: state.pathParameters['id']),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/routines',
                builder: (context, state) => const RoutinesPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage()),
          ]),
        ],
      ),
    ],
  );
});

/// Root widget. Also the app-lifecycle sync trigger: coming back to the
/// foreground kicks a pull→push cycle (silent no-op unless configured,
/// signed in, or already running — see [SyncController.syncNow]).
class KineticApp extends ConsumerStatefulWidget {
  const KineticApp({super.key});

  @override
  ConsumerState<KineticApp> createState() => _KineticAppState();
}

class _KineticAppState extends ConsumerState<KineticApp>
    with WidgetsBindingObserver {
  static const _quickActions = QuickActions();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initQuickActions();
    _rearmReminder();
  }

  /// Re-arm the weekly reminder on every launch. The plugin's boot receiver
  /// restores pending alarms across reboots; this catches the rest — time
  /// zone changes, missed restores — and is idempotent (same stable id).
  Future<void> _rearmReminder() async {
    try {
      final s = ref.read(settingsProvider);
      if (!s.reminderEnabled) return;
      await ref.read(weeklyReminderProvider).schedule(
            weekday: s.reminderWeekday,
            hour: s.reminderHour,
            minute: s.reminderMinute,
          );
    } catch (_) {}
  }

  /// Home-screen shortcut: "Start Workout" boots (or resumes) a session and
  /// jumps straight into the logger. Every call is guarded — the platform
  /// channel is absent in widget tests and a missing shortcut must never
  /// break startup.
  Future<void> _initQuickActions() async {
    try {
      await _quickActions.initialize(_onQuickAction);
      await _quickActions.setShortcutItems(const [
        ShortcutItem(
          type: 'start_workout',
          localizedTitle: 'Start Workout',
          icon: 'ic_stat_kinetic', // resolved by name from res/drawable
        ),
      ]);
    } catch (_) {}
  }

  Future<void> _onQuickAction(String shortcutType) async {
    if (shortcutType != 'start_workout') return;
    try {
      await ref.read(workoutSessionProvider.notifier).startWorkout();
      if (!mounted) return;
      final router = ref.read(_routerProvider);
      // The app may already be sitting on the logger (relaunch from the
      // background via the same shortcut) — don't stack a second page.
      if (router.state.uri.path != '/workout') router.push('/workout');
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(syncControllerProvider.notifier).syncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'Kinetic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark(amoled: settings.amoledBlack),
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline_rounded),
            selectedIcon: Icon(Icons.play_circle_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_rounded),
            selectedIcon: Icon(Icons.playlist_add_check_circle_rounded),
            label: 'Routines',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_rounded),
            selectedIcon: Icon(Icons.insights),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
