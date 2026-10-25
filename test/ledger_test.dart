import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/ledger/ledger.dart';
import 'package:kinetic/core/theme/app_theme.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('AppBottomNav renders five tabs and reports taps', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      _host(AppBottomNav(selectedIndex: 2, onSelected: (i) => selected = i)),
    );

    for (final label in AppBottomNav.labels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(LedgerGlyph), findsNWidgets(5));

    await tester.tap(find.byKey(const Key('nav-3')));
    await tester.pump();
    expect(selected, 3);
  });

  testWidgets('PushKey travels 3px while pressed and fires once', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        Center(
          child: SizedBox(
            width: 240,
            child: PushKey(label: 'Start Workout', onPressed: () => taps++),
          ),
        ),
      ),
    );

    expect(find.text('Start Workout'), findsOneWidget);
    expect(
      tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned)).top,
      0,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Start Workout')),
    );
    await tester.pump(const Duration(milliseconds: 160));
    expect(
      tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned)).top,
      3,
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(
      tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned)).top,
      0,
    );
  });

  testWidgets('disabled PushKey ignores taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        Center(
          child: SizedBox(
            width: 240,
            child: PushKey(
              label: 'Start Workout',
              enabled: false,
              onPressed: () => taps++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start Workout'));
    await tester.pumpAndSettle();
    expect(taps, 0);
  });

  testWidgets('Stamp uppercases its mark and rotates', (tester) async {
    await tester.pumpWidget(_host(const Center(child: Stamp('pr'))));

    expect(find.text('PR'), findsOneWidget);
    expect(find.byType(Transform), findsWidgets);
  });

  testWidgets('Tally paints its marks', (tester) async {
    await tester.pumpWidget(_host(const Center(child: Tally(count: 7))));

    final size = tester.getSize(find.byType(Tally));
    expect(size.width, greaterThan(30));
    expect(size.height, 14);
  });

  testWidgets('StatBlocks lays metrics out with hairline dividers', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 360,
          child: StatBlocks(
            children: [
              Metric(label: 'Sessions', value: '04'),
              Metric(label: 'Streak', value: '6', unit: 'wk'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('SESSIONS'), findsOneWidget);
    expect(find.text('04'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('wk'), findsOneWidget);
  });

  testWidgets('LedgerPanel keeps an optional numbered header', (tester) async {
    await tester.pumpWidget(
      _host(
        const LedgerPanel(
          index: '02',
          title: 'This week',
          meta: 'MON — SUN',
          child: Text('content'),
        ),
      ),
    );

    expect(find.text('02'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(find.text('MON — SUN'), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });
}
