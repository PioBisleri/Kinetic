import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_actions/quick_actions.dart';

import 'core/notifications/weekly_reminder_service.dart';
import 'core/navigation/shell_navigation.dart';
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
import 'features/routines/weekly_plan_page.dart';
import 'features/settings/settings_page.dart';
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
      // App settings — pushed over the shell (back arrow returns).
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      // View-only weekly plan — also pushed over the shell.
      GoRoute(
        path: '/schedule',
        builder: (context, state) => const WeeklyPlanPage(),
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

class _AppShell extends ConsumerWidget {
  const _AppShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: ref.watch(shellScaffoldKeyProvider),
      // Light scrim: the drawer is frosted glass, so the page behind it
      // should stay visible (blurred) instead of being crushed to black.
      drawerScrimColor: Colors.black.withValues(alpha: 0.35),
      drawer: KineticDrawer(
        currentIndex: shell.currentIndex,
        onBranchSelected: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
      ),
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

/// Left drawer on the shell — a frosted-glass panel: translucent tint over
/// a blurred snapshot of the current tab, colored entirely from the app's
/// semantic tokens (dark/light/AMOLED all follow automatically).
///
/// Contents: a Start Workout button, the four tabs (mirroring the bottom
/// bar so the drawer never feels empty), and the non-tab destinations —
/// exercise library, weekly plan, settings. Drawer content is only built
/// while open (Scaffold latches it), so the tab labels here never collide
/// with the bottom bar's in widget tests.
class KineticDrawer extends ConsumerWidget {
  const KineticDrawer({
    super.key,
    required this.currentIndex,
    required this.onBranchSelected,
  });

  /// Index of the visible branch, for tinting the active tab row.
  final int currentIndex;

  /// Hands the index back to the shell's [StatefulNavigationShell].
  final ValueChanged<int> onBranchSelected;

  /// (unselected icon, selected icon, label) — mirrors the bottom bar.
  static const _tabs = [
    (Icons.play_circle_outline_rounded, Icons.play_circle_rounded, 'Home'),
    (Icons.list_alt_rounded, Icons.playlist_add_check_circle_rounded,
        'Routines'),
    (Icons.insights_rounded, Icons.insights, 'Analytics'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          // The tint IS a Material: ListTiles paint their background and
          // ink splashes on the nearest Material ancestor, so a plain
          // ColoredBox here would hide both (framework assertion).
          child: Material(
            color: context.surface.withValues(alpha: 0.60),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _header(context),
                  _startWorkoutButton(context, ref),
                  const Divider(height: 1),
                  _sectionLabel(context, 'Navigate'),
                  for (var i = 0; i < _tabs.length; i++)
                    _tabTile(context, i),
                  const Divider(height: 1),
                  _sectionLabel(context, 'App'),
                  _routeTile(
                    context,
                    icon: Icons.fitness_center_outlined,
                    title: 'Exercise Library',
                    path: '/library',
                  ),
                  _routeTile(
                    context,
                    icon: Icons.calendar_view_week_outlined,
                    title: 'Schedule',
                    path: '/schedule',
                  ),
                  _routeTile(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    path: '/settings',
                  ),
                  _versionFooter(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KINETIC',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Offline-first training log',
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
          ],
        ),
      );

  Widget _startWorkoutButton(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: FilledButton.icon(
          key: const Key('drawer-start-workout'),
          onPressed: () => _startWorkout(context, ref),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Workout'),
        ),
      );

  /// Same contract as the home-screen quick action: boot (or resume) a
  /// session, then land on the logger — never stacking a second page.
  Future<void> _startWorkout(BuildContext context, WidgetRef ref) async {
    final router = ref.read(_routerProvider);
    try {
      await ref.read(workoutSessionProvider.notifier).startWorkout();
    } catch (e) {
      debugPrint('Start workout from drawer failed: $e');
      return;
    }
    if (!context.mounted) return;
    Scaffold.of(context).closeDrawer();
    if (router.state.uri.path != '/workout') router.push('/workout');
  }

  Widget _sectionLabel(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: context.textTertiary,
          ),
        ),
      );

  Widget _tabTile(BuildContext context, int index) {
    final (icon, selectedIcon, label) = _tabs[index];
    final active = index == currentIndex;
    return ListTile(
      key: Key('drawer-tab-$index'),
      dense: true,
      leading: Icon(
        active ? selectedIcon : icon,
        size: 22,
        color: active ? AppColors.accent : context.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: active ? context.textPrimary : context.textSecondary,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      onTap: () {
        Scaffold.of(context).closeDrawer();
        onBranchSelected(index);
      },
    );
  }

  Widget _routeTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String path,
  }) =>
      ListTile(
        key: Key('drawer-${path.replaceAll('/', '')}'),
        dense: true,
        leading: Icon(icon, size: 22, color: context.textSecondary),
        title: Text(
          title,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          // The drawer is part of the shell scaffold, not a route.
          Scaffold.of(context).closeDrawer();
          context.push(path);
        },
      );

  Widget _versionFooter(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(
          'Kinetic 0.1.1 · offline-first',
          style: TextStyle(fontSize: 12, color: context.textTertiary),
        ),
      );
}
