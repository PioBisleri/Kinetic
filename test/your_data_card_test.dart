import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/app.dart';
import 'package:kinetic/core/database/database.dart';
import 'package:kinetic/core/database/seed_service.dart';
import 'package:kinetic/core/settings/settings.dart';
import 'package:kinetic/features/profile/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Your data" card (Round 5): every field saves independently onto the
/// `local` profile row, and the derived BMI row appears once height +
/// bodyweight exist.
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

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
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

  Future<void> openProfile(WidgetTester tester) async {
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
  }

  /// ListView children below the fold aren't built — drag until [target]
  /// exists (same trick as widget_test's scrollProfileUntil).
  Future<void> scrollUntilBuilt(
    WidgetTester tester,
    Finder target, {
    int maxDrags = 8,
  }) async {
    final list = find.descendant(
      of: find.byType(ProfilePage),
      matching: find.byType(ListView),
    );
    for (var i = 0; i < maxDrags && target.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
  }

  /// Type into a field and fire `onSubmitted` — how every input in the
  /// card persists.
  Future<void> submit(WidgetTester tester, Finder field, String text) async {
    await scrollUntilBuilt(tester, field);
    await tester.enterText(field, text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  Future<Profile?> localProfile() async => (db.profiles.select()
        ..where((p) => p.id.equals('local')))
      .getSingleOrNull();

  testWidgets('name and height save on submit; BMI follows bodyweight',
      (tester) async {
    await pumpApp(tester);
    await openProfile(tester);

    // Top rows are in the first viewport; fill them first.
    await submit(tester, find.byKey(const Key('profile-name')), 'Pio');
    expect((await localProfile())?.username, 'Pio');

    await submit(tester, find.byKey(const Key('profile-height')), '180');
    expect((await localProfile())?.heightCm, 180);

    // Height alone isn't enough for BMI — the row hints what's missing.
    await scrollUntilBuilt(tester, find.byKey(const Key('profile-bmi')));
    expect(find.text('Add height + weight'), findsOneWidget);

    await submit(tester, find.byKey(const Key('bodyweight-input')), '72');
    final profile = await localProfile();
    expect(profile?.bodyweightKg, 72);
    expect(profile?.heightCm, 180); // partial saves never clobber

    // 180 cm / 72 kg → 22.2, WHO-normal band.
    expect(find.text('22.2 · Normal'), findsOneWidget);
    expect(find.text('Add height + weight'), findsNothing);

    await endApp(tester);
  });

  testWidgets('imperial height: ft + in fields convert to canonical cm',
      (tester) async {
    SharedPreferences.setMockInitialValues({'unit': 'lbs'});
    prefs = await SharedPreferences.getInstance();

    await pumpApp(tester);
    await openProfile(tester);

    // One full field first (ft only, in still empty) → not saved yet.
    await submit(tester, find.byKey(const Key('profile-height')), '5');
    expect((await localProfile())?.heightCm, isNull);

    await submit(tester, find.byKey(const Key('profile-height-in')), '11');
    expect((await localProfile())?.heightCm, closeTo(180.34, 0.01));

    await endApp(tester);
  });

  testWidgets('sex and goal dropdowns persist their values',
      (tester) async {
    await pumpApp(tester);
    await openProfile(tester);

    await scrollUntilBuilt(tester, find.byKey(const Key('profile-sex')));
    await tester.tap(find.byKey(const Key('profile-sex')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();
    expect((await localProfile())?.sex, 'female');

    await scrollUntilBuilt(tester, find.byKey(const Key('profile-goal')));
    await tester.tap(find.byKey(const Key('profile-goal')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hypertrophy'));
    await tester.pumpAndSettle();
    expect((await localProfile())?.trainingGoal, 'hypertrophy');

    await endApp(tester);
  });

  testWidgets('date of birth: picker stores the ISO date and shows age',
      (tester) async {
    await pumpApp(tester);
    await openProfile(tester);

    await scrollUntilBuilt(tester, find.byKey(const Key('profile-dob-pick')));
    await tester.tap(find.byKey(const Key('profile-dob-pick')));
    await tester.pumpAndSettle();

    // The picker opens on the initial date — confirm it.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect((await localProfile())?.birthDate, '2000-01-01');
    expect(find.textContaining('years old'), findsOneWidget);

    await endApp(tester);
  });

  testWidgets('body fat saves within the plausible range only',
      (tester) async {
    await pumpApp(tester);
    await openProfile(tester);

    await scrollUntilBuilt(tester, find.byKey(const Key('profile-bf')));

    // Out-of-range input is ignored, valid input saves.
    await submit(tester, find.byKey(const Key('profile-bf')), '95');
    expect((await localProfile())?.bodyFatPct, isNull);

    await submit(tester, find.byKey(const Key('profile-bf')), '14.5');
    expect((await localProfile())?.bodyFatPct, 14.5);

    await endApp(tester);
  });
}
