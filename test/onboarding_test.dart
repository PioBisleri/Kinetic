import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/app.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/core/utils/day_key.dart';
import 'package:kinetic/features/onboarding/onboarding_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedService(db).ensureSeeded();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() => db.close());

  Future<void> pumpOnboarding(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          onboardingPendingProvider.overrideWithValue(true),
        ],
        child: const KineticApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> endApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('setup saves profile, units, height and the first weigh-in', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    expect(find.byKey(const Key('onboarding-page')), findsOneWidget);
    expect(find.text('Your training,\non the record.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('onboarding-name')), 'Pio');
    await tester.ensureVisible(
      find.byKey(const Key('onboarding-goal-strength')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-goal-strength')));
    await tester.ensureVisible(find.byKey(const Key('onboarding-unit-lbs')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-unit-lbs')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    expect(find.text('Set your baseline.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('onboarding-weight')), '180');
    await tester.enterText(find.byKey(const Key('onboarding-height-ft')), '5');
    await tester.enterText(find.byKey(const Key('onboarding-height-in')), '11');
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-page')), findsNothing);
    expect(find.text('Start Workout'), findsOneWidget);
    expect(prefs.getBool(onboardingDoneKey), isTrue);
    expect(prefs.getString('unit'), 'lbs');

    final profile = await (db.select(
      db.profiles,
    )..where((p) => p.id.equals('local'))).getSingle();
    expect(profile.username, 'Pio');
    expect(profile.trainingGoal, 'strength');
    expect(profile.bodyweightKg, closeTo(81.65, 0.02));
    expect(profile.heightCm, closeTo(180.34, 0.02));

    final metric = await db.bodyMetricOnce(dayKey(DateTime.now()));
    expect(metric?.weightKg, closeTo(81.65, 0.02));

    await endApp(tester);
  });

  testWidgets('skip marks setup done without creating a profile', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    await tester.tap(find.byKey(const Key('onboarding-skip-setup')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-page')), findsNothing);
    expect(find.text('Start Workout'), findsOneWidget);
    expect(prefs.getBool(onboardingDoneKey), isTrue);
    expect(await db.select(db.profiles).getSingleOrNull(), isNull);

    await endApp(tester);
  });
}
