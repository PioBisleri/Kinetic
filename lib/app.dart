import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      darkTheme: AppTheme.dark,
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
