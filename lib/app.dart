import 'dart:async' show StreamSubscription, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quick_actions/quick_actions.dart';

import 'core/database/database.dart';
import 'core/ledger/ledger.dart';
import 'core/notifications/weekly_reminder_service.dart';
import 'core/notifications/water_reminder_service.dart';
import 'core/navigation/shell_navigation.dart';
import 'core/settings/settings.dart';
import 'core/sync/sync_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/analytics/analytics_page.dart';
import 'features/home/home_page.dart';
import 'features/home/home_screen_widget.dart';
import 'features/health/live_activity_service.dart';
import 'features/history/history_page.dart';
import 'features/profile/profile_page.dart';
import 'features/nutrition/diet_page.dart';
import 'features/onboarding/onboarding_gate.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/routines/exercise_detail_page.dart';
import 'features/routines/exercise_edit_page.dart';
import 'features/routines/exercise_library_page.dart';
import 'features/routines/routine_editor_page.dart';
import 'features/routines/routines_page.dart';
import 'features/routines/weekly_plan_page.dart';
import 'features/settings/settings_page.dart';
import 'features/workout/application/workout_session_notifier.dart';
import 'features/workout/live_workout_page.dart';
import 'features/workout/workout_detail_page.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  final onboardingPending = ref.watch(onboardingPendingProvider);
  return GoRouter(
    initialLocation: onboardingPending ? '/onboarding' : '/',
    routes: [
      // First-run setup — full-screen, outside the shell.
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      // Full-screen live logger — pushed over the shell, so no bottom nav.
      GoRoute(
        path: '/workout',
        builder: (context, state) => const LiveWorkoutPage(),
      ),
      // Read-only history viewer for a finished workout (Round 9).
      GoRoute(
        path: '/workout-history/:id',
        builder: (context, state) =>
            WorkoutDetailPage(workoutId: state.pathParameters['id']!),
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
        builder: (context, state) =>
            ExerciseEditPage(exerciseId: state.pathParameters['id']),
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
      // Diet: daily macros, water, food library.
      GoRoute(path: '/diet', builder: (context, state) => const DietPage()),
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
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (context, state) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/routines',
                builder: (context, state) => const RoutinesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
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

  /// Home-screen widget taps (warm relaunches).
  StreamSubscription<Uri?>? _widgetClickSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initQuickActions();
    _initHomeWidget();
    _updateHomeWidget();
    _rearmReminder();
    _rearmWaterReminder();
    // Live activity (Round 9): re-arm + adopt the service's step count on
    // every launch — same idempotent, never-throw contract as above.
    unawaited(_refLiveReconcile());
  }

  Future<void> _refLiveReconcile() async {
    try {
      await ref.read(liveActivityControllerProvider).reconcile();
    } catch (_) {}
  }

  /// Re-arm the weekly reminder on every launch. The plugin's boot receiver
  /// restores pending alarms across reboots; this catches the rest — time
  /// zone changes, missed restores — and is idempotent (same stable id).
  Future<void> _rearmReminder() async {
    try {
      final s = ref.read(settingsProvider);
      if (!s.reminderEnabled) return;
      await ref
          .read(weeklyReminderProvider)
          .schedule(
            weekday: s.reminderWeekday,
            hour: s.reminderHour,
            minute: s.reminderMinute,
          );
    } catch (_) {}
  }

  /// Re-arm the water reminder on every launch, same contract as
  /// [_rearmReminder]: idempotent, driven by settings, never throws.
  Future<void> _rearmWaterReminder() async {
    try {
      final s = ref.read(settingsProvider);
      if (!s.waterReminderEnabled) return;
      await ref
          .read(waterReminderProvider)
          .schedule(
            startHour: s.waterStartHour,
            endHour: s.waterEndHour,
            intervalMin: s.waterIntervalMin,
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

  /// Home-screen widget taps: cold start (`initiallyLaunched…`) and warm
  /// relaunches (`widgetClicked`) both carry `kinetic://widget/workout`,
  /// handled by the exact same flow as the quick action above. Every call
  /// is guarded — the channel is absent in widget tests.
  void _initHomeWidget() {
    try {
      unawaited(
        HomeWidget.initiallyLaunchedFromHomeWidget()
            .then(_onWidgetLaunch)
            .catchError((Object _) {}),
      );
      _widgetClickSub = HomeWidget.widgetClicked.listen(
        _onWidgetLaunch,
        onError: (Object _) {},
      );
    } catch (_) {}
  }

  Future<void> _onWidgetLaunch(Uri? uri) async {
    if (uri == null || uri.path != '/workout') return;
    await _onQuickAction('start_workout');
  }

  /// Refresh the home-screen widget's numbers — best-effort and never
  /// throws (see [updateHomeScreenWidget]).
  Future<void> _updateHomeWidget() async {
    try {
      await updateHomeScreenWidget(
        ref.read(databaseProvider),
        ref.read(settingsProvider).unit,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _widgetClickSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(syncControllerProvider.notifier).syncNow();
      // Time may have moved on (a new week, a streak at risk) — catch up.
      _updateHomeWidget();
      // Backgrounded time may have accrued steps / water settings — adopt
      // and re-apply the live notification snapshot. Never throws.
      _refLiveReconcile();
    } else if (state == AppLifecycleState.paused) {
      // Push whatever just changed (finish, edits) while we're in the
      // foreground — the launcher redraws before the user sees it again.
      _updateHomeWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'Kinetic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: AppAccent.byId(settings.accent).color),
      darkTheme: AppTheme.dark(
        accent: AppAccent.byId(settings.accent).color,
        amoled: settings.amoledBlack,
      ),
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
      // The drawer is an opaque ledger page; dim the shell behind it so the
      // index reads as a separate sheet rather than a floating overlay.
      drawerScrimColor: Colors.black.withValues(alpha: 0.45),
      drawer: KineticDrawer(
        currentIndex: shell.currentIndex,
        onBranchSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
      body: shell,
      bottomNavigationBar: AppBottomNav(
        selectedIndex: shell.currentIndex,
        onSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}

/// Left drawer on the shell — an opaque ledger index rather than a floating
/// menu. It mirrors the tabs, exposes the non-tab destinations, and keeps the
/// blank-session action at the top. Content is only built while open, so the
/// tab labels never collide with the bottom bar in widget tests.
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

  static const _tabs = ['Home', 'Routines', 'Analytics', 'History', 'Profile'];

  static const _routes = [
    ('LIB', 'Exercise Library', '/library'),
    ('DIET', 'Diet', '/diet'),
    ('WK', 'Schedule', '/schedule'),
    ('SET', 'Settings', '/settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: context.background,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: context.border)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Rule(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: AppSpace.x3),
                    _sectionHead(context, '00', 'Session', 'START'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.x5,
                        AppSpace.x3,
                        AppSpace.x5,
                        0,
                      ),
                      child: PushKey(
                        key: const Key('drawer-start-workout'),
                        label: 'Start Workout',
                        height: 50,
                        onPressed: () => _startWorkout(context, ref),
                        icon: LedgerGlyph(
                          LedgerGlyphType.play,
                          size: 15,
                          strokeWidth: 2,
                          color: onAccent(context.accent),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.x5,
                        AppSpace.x2,
                        AppSpace.x5,
                        AppSpace.x2,
                      ),
                      child: Text(
                        'Blank session',
                        style: AppType.metaSm.copyWith(
                          color: context.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.x4),
                    _sectionHead(context, '01', 'Navigate', '05'),
                    for (var i = 0; i < _tabs.length; i++) _tabTile(context, i),
                    const SizedBox(height: AppSpace.x4),
                    _sectionHead(context, '02', 'App', 'TOOLS'),
                    for (final route in _routes)
                      _routeTile(
                        context,
                        code: route.$1,
                        title: route.$2,
                        path: route.$3,
                      ),
                    const SizedBox(height: AppSpace.x5),
                  ],
                ),
              ),
              Rule(),
              _versionFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.x5,
      AppSpace.x4,
      AppSpace.x5,
      AppSpace.x4,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KINETIC',
          style: AppType.h1.copyWith(
            fontSize: 26,
            letterSpacing: 3.2,
            height: 1,
          ),
        ),
        const SizedBox(height: AppSpace.x2),
        Text(
          'Offline-first training log',
          style: AppType.bodySm.copyWith(color: context.textSecondary),
        ),
        const SizedBox(height: AppSpace.x3),
        Row(
          children: [
            Stamp('Local only', color: context.textTertiary, rotate: false),
            const Spacer(),
            Text(
              'FIELD / 02',
              style: AppType.metaSm.copyWith(color: context.textTertiary),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _sectionHead(
    BuildContext context,
    String index,
    String title,
    String meta,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.x5,
      0,
      AppSpace.x5,
      AppSpace.x2,
    ),
    child: SectionHead(index: index, title: title, meta: meta),
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

  Widget _tabTile(BuildContext context, int index) {
    final label = _tabs[index];
    final active = index == currentIndex;
    return Semantics(
      selected: active,
      child: Material(
        color: active
            ? context.accent.withValues(alpha: 0.07)
            : Colors.transparent,
        child: InkWell(
          key: Key('drawer-tab-$index'),
          onTap: () {
            Scaffold.of(context).closeDrawer();
            onBranchSelected(index);
          },
          splashColor: context.accent.withValues(alpha: 0.06),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: active ? context.accent : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(18, 0, AppSpace.x5, 0),
            child: Row(
              children: [
                LedgerGlyph(
                  tabGlyph(index),
                  size: 19,
                  color: active ? context.accent : context.textSecondary,
                ),
                const SizedBox(width: AppSpace.x3),
                Expanded(
                  child: Text(
                    label,
                    style: AppType.body.copyWith(
                      color: active
                          ? context.textPrimary
                          : context.textSecondary,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  '0${index + 1}',
                  style: AppType.metaSm.copyWith(
                    color: active ? context.accent : context.textTertiary,
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: AppSpace.x2),
                  Transform.rotate(
                    angle: 0.785398,
                    child: Container(
                      width: 5,
                      height: 5,
                      color: context.accent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _routeTile(
    BuildContext context, {
    required String code,
    required String title,
    required String path,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('drawer-${path.replaceAll('/', '')}'),
        onTap: () {
          // The drawer is part of the shell scaffold, not a route.
          Scaffold.of(context).closeDrawer();
          context.push(path);
        },
        splashColor: context.accent.withValues(alpha: 0.06),
        child: Container(
          height: 48,
          padding: const EdgeInsets.fromLTRB(AppSpace.x5, 0, AppSpace.x5, 0),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: context.border),
                  borderRadius: BorderRadius.circular(AppRadius.data),
                ),
                child: Text(
                  code,
                  style: AppType.metaSm.copyWith(color: context.textTertiary),
                ),
              ),
              const SizedBox(width: AppSpace.x3),
              Expanded(
                child: Text(
                  title,
                  style: AppType.body.copyWith(color: context.textPrimary),
                ),
              ),
              LedgerGlyph(
                LedgerGlyphType.chevronRight,
                size: 12,
                color: context.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _versionFooter(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.x5,
      AppSpace.x3,
      AppSpace.x5,
      AppSpace.x3,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Kinetic · offline-first',
            style: AppType.metaSm.copyWith(color: context.textTertiary),
          ),
        ),
        Text(
          'NO CLOUD',
          style: AppType.metaSm.copyWith(color: context.textTertiary),
        ),
      ],
    ),
  );
}
