import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/core/theme/app_theme.dart';
import 'package:kinetic/core/widgets/section_card.dart';

/// Round 9 — the F1 polish foundation: real textTheme anchors on the
/// ThemeData, shared style idioms and the danger color token.
void main() {
  test('theme textTheme carries the shared scales (dark + light)', () {
    for (final theme in [AppTheme.dark(), AppTheme.light()]) {
      final display = theme.textTheme.displaySmall!;
      expect(display.fontSize, 24);
      expect(display.fontWeight, FontWeight.w800);
      expect(display.letterSpacing, -0.5);

      final caption = theme.textTheme.labelSmall!;
      expect(caption.fontSize, 11);
      expect(caption.fontWeight, FontWeight.w800);
      expect(caption.letterSpacing, 1.1);

      // Unfilled entries stay Material's own defaults (ListTiles etc.).
      expect(theme.textTheme.titleMedium!.fontSize, isNot(17));
    }
  });

  test('danger color token exists in both brightnesses', () {
    expect(AppColors.danger, const Color(0xFFE53935));
  });

  testWidgets('SectionCard header renders via the theme caption token',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: const Scaffold(body: SectionCard(title: 'History', children: [])),
    ));
    final text = tester.widget<Text>(find.text('HISTORY'));
    expect(text.style!.fontSize, 11);
    expect(text.style!.fontWeight, FontWeight.w800);
    expect(text.style!.letterSpacing, 1.1);
  });

  test('AppStyles title/body idioms', () {
    expect(AppStyles.title.fontSize, 17);
    expect(AppStyles.title.fontWeight, FontWeight.w700);
    expect(AppStyles.body.fontSize, 14.5);
    expect(AppStyles.body.color, isNull);
  });
}
