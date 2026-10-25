import 'package:flutter/material.dart';

/// User-selectable accent palettes (Round 9.2). The accent drives
/// button/nav/chart colors through [ColorScheme.fromSeed]; `kinetic` is the
/// shipped default and what "Reset to default" restores.
class AppAccent {
  AppAccent._(this.id, this.label, this.color);

  final String id;
  final String label;
  final Color color;

  static final List<AppAccent> all = [
    AppAccent._('kinetic', 'Kinetic', const Color(0xFF22D3A5)),
    AppAccent._('ember', 'Ember', const Color(0xFFFF6D4D)),
    AppAccent._('rose', 'Rose', const Color(0xFFF472B6)),
    AppAccent._('violet', 'Violet', const Color(0xFFA78BFA)),
    AppAccent._('ocean', 'Ocean', const Color(0xFF38BDF8)),
    AppAccent._('lime', 'Lime', const Color(0xFFB5E848)),
    AppAccent._('amber', 'Amber', const Color(0xFFFBBF24)),
    AppAccent._('steel', 'Steel', const Color(0xFF64748B)),
  ];

  static const defaultId = 'kinetic';

  static AppAccent byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);
}

/// Ink that stays readable on top of an accent fill (dark ink on bright
/// accents, white ink on the dark ones).
Color onAccent(Color accent) =>
    accent.computeLuminance() > 0.45 ? const Color(0xFF04211A) : Colors.white;

/// Kinetic design tokens (Round 11 "Workshop Ledger"): warm charcoal by
/// default, hairline rules, tabular numerals.
abstract final class AppColors {
  // Surfaces — warm charcoal, not cool gray.
  static const background = Color(0xFF0C0B09);
  static const surface = Color(0xFF121110);
  static const surfaceElevated = Color(0xFF1A1815);
  static const border = Color(0xFF28251F);

  // AMOLED true-black surfaces (dark brightness only).
  static const amoledBackground = Color(0xFF000000);
  static const amoledSurface = Color(0xFF0A0A08);
  static const amoledElevated = Color(0xFF14130F);
  static const amoledBorder = Color(0xFF232019);

  // Text
  static const textPrimary = Color(0xFFF1EEE8);
  static const textSecondary = Color(0xFF8A857C);
  static const textTertiary = Color(0xFF5E5A52);

  // Paper (light) surfaces
  static const paperBackground = Color(0xFFF4F1EA);
  static const paperSurface = Color(0xFFFBFAF6);
  static const paperElevated = Color(0xFFEAE6DC);
  static const paperBorder = Color(0xFFDAD4C6);
  static const paperTextPrimary = Color(0xFF14120F);
  static const paperTextSecondary = Color(0xFF5C574E);
  static const paperTextTertiary = Color(0xFF8A8478);

  // Brand & data
  static const accent = Color(0xFF22D3A5); // kinetic teal
  static const accentDim = Color(0xFF17614E);

  /// Fixed warm "record" signal — PRs, streaks, records. Independent of the
  /// user's accent palette so it never collides with it.
  static const signal = Color(0xFFFF8A3D);
  static const signalInk = Color(0xFF2A1204);

  static const heatHot = Color(0xFFE5484D); // freshly trained
  static const heatWarm = Color(0xFFF2763F);
  static const heatRest = Color(0xFF3A3630); // recovering
  static const heatCold = Color(0xFF3A3630); // untrained

  /// Destructive-action tint (Round 9).
  static const danger = Color(0xFFE53935);

  // Grades
  static const gradeS = Color(0xFFFFC94D);
  static const gradeA = Color(0xFF6FBF73);
  static const gradeB = Color(0xFF5AA9E6);
  static const gradeC = Color(0xFFB4C25A);
  static const gradeD = Color(0xFFF2763F);
  static const gradeF = Color(0xFF8A857C);

  static Color gradeColor(String grade) => switch (grade) {
    'S' => gradeS,
    'A' => gradeA,
    'B' => gradeB,
    'C' => gradeC,
    'D' => gradeD,
    _ => gradeF,
  };
}

/// Spacing scale — 4px baseline.
abstract final class AppSpace {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 28.0;
  static const x8 = 40.0;

  /// Standard page gutter.
  static const gutter = x5;

  /// Vertical gap between sections.
  static const section = x6;
}

/// Corner radii — data surfaces stay near-square, actions are chunkier.
abstract final class AppRadius {
  static const data = 2.0;
  static const control = 6.0;
  static const input = 4.0;
}

/// Motion durations/curves. Route transitions stay instant; only in-page
/// affordances animate.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 160);
  static const curve = Curves.easeOutCubic;
}

/// Typography: Bricolage for display, Archivo for UI/body, JetBrains Mono
/// (tabular) for every numeral, unit and micro-label.
abstract final class AppType {
  static const _display = 'Bricolage';
  static const _ui = 'Archivo';
  static const mono = 'JetBrainsMono';

  static const tabular = [FontFeature.tabularFigures()];

  /// Hero totals (Home weekly volume, big streaks).
  static const hero = TextStyle(
    fontFamily: _display,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -1.2,
  );

  /// Screen titles.
  static const h1 = TextStyle(
    fontFamily: _display,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.05,
    letterSpacing: -0.8,
  );

  /// Section titles.
  static const h2 = TextStyle(
    fontFamily: _ui,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const body = TextStyle(
    fontFamily: _ui,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const bodySm = TextStyle(
    fontFamily: _ui,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static const button = TextStyle(
    fontFamily: _ui,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  /// Uppercase micro-label ('TODAY', '04 — VOLUME', 'WATER').
  static const meta = TextStyle(
    fontFamily: mono,
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.6,
  );

  /// Smaller meta for dense rows.
  static const metaSm = TextStyle(
    fontFamily: mono,
    fontSize: 9.5,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 1.4,
  );

  /// Data numerals (tabular).
  static const data = TextStyle(
    fontFamily: mono,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.2,
    fontFeatures: tabular,
  );

  static const dataSm = TextStyle(
    fontFamily: mono,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.1,
    fontFeatures: tabular,
  );

  static const dataLg = TextStyle(
    fontFamily: mono,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.15,
    letterSpacing: -0.4,
    fontFeatures: tabular,
  );

  static const dataXl = TextStyle(
    fontFamily: mono,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.6,
    fontFeatures: tabular,
  );

  static const dataHero = TextStyle(
    fontFamily: mono,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.05,
    letterSpacing: -1.0,
    fontFeatures: tabular,
  );

  /// Tabular overrides that keep the family/features when reusing a size.
  static TextStyle tabularOf(TextStyle style) =>
      style.copyWith(fontFamily: mono, fontFeatures: tabular);
}

/// Carries the AMOLED preference inside [ThemeData] so the
/// [AppColorsContext] getters (which only see `Theme.of`) can resolve the
/// true-black variants without a Riverpod dependency.
class AmoledTokens extends ThemeExtension<AmoledTokens> {
  const AmoledTokens({required this.enabled});

  final bool enabled;

  @override
  AmoledTokens copyWith({bool? enabled}) =>
      AmoledTokens(enabled: enabled ?? this.enabled);

  @override
  AmoledTokens lerp(ThemeExtension<AmoledTokens>? other, double t) =>
      other is AmoledTokens ? other : this;
}

/// Theme-bound accessors for the semantic palette above.
///
/// Widget code reads these as `context.textPrimary` etc. instead of the
/// statics so light mode gets the warm paper values while dark stays exactly
/// the constants above — unless AMOLED black is on, where surfaces swap to
/// the true-black variants. Each mapping mirrors its colorScheme
/// counterpart (onSurface / surface / surfaceContainer / outline /
/// scaffoldBackground), which [AppTheme] seeds from the same numbers.
extension AppColorsContext on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  /// True only in dark brightness with the AMOLED toggle on.
  bool get _amoled =>
      _isDark && (Theme.of(this).extension<AmoledTokens>()?.enabled ?? false);

  Color get textPrimary =>
      _isDark ? AppColors.textPrimary : AppColors.paperTextPrimary;
  Color get textSecondary =>
      _isDark ? AppColors.textSecondary : AppColors.paperTextSecondary;
  Color get textTertiary =>
      _isDark ? AppColors.textTertiary : AppColors.paperTextTertiary;
  Color get surface => _amoled
      ? AppColors.amoledSurface
      : _isDark
      ? AppColors.surface
      : AppColors.paperSurface;
  Color get surfaceElevated => _amoled
      ? AppColors.amoledElevated
      : _isDark
      ? AppColors.surfaceElevated
      : AppColors.paperElevated;
  Color get background => _amoled
      ? AppColors.amoledBackground
      : _isDark
      ? AppColors.background
      : AppColors.paperBackground;
  Color get border => _amoled
      ? AppColors.amoledBorder
      : _isDark
      ? AppColors.border
      : AppColors.paperBorder;

  /// App-wide danger tint; light mode darkens for contrast.
  Color get danger => _isDark ? AppColors.danger : const Color(0xFFB3261E);

  /// The user-selected accent (Round 9.2) — resolved from the seeded
  /// color scheme so every widget follows the Appearance palette.
  Color get accent => Theme.of(this).colorScheme.primary;

  /// Dimmed accent for backgrounds/segments that need a quieter accent.
  Color get accentDim => accent.withValues(alpha: 0.45);

  /// Fixed warm record signal (PRs, streaks) — never the accent.
  Color get signal => _isDark ? AppColors.signal : const Color(0xFFD9620F);
}

abstract final class AppTheme {
  static ThemeData dark({
    Color accent = AppColors.accent,
    bool amoled = false,
  }) => _base(
    accent: accent,
    brightness: Brightness.dark,
    scaffold: amoled ? AppColors.amoledBackground : AppColors.background,
    surface: amoled ? AppColors.amoledSurface : AppColors.surface,
    onSurface: AppColors.textPrimary,
    elevated: amoled ? AppColors.amoledElevated : AppColors.surfaceElevated,
    outline: amoled ? AppColors.amoledBorder : AppColors.border,
    amoled: amoled,
  );

  static ThemeData light({Color accent = AppColors.accent}) => _base(
    accent: accent,
    brightness: Brightness.light,
    scaffold: AppColors.paperBackground,
    surface: AppColors.paperSurface,
    onSurface: AppColors.paperTextPrimary,
    elevated: AppColors.paperElevated,
    outline: AppColors.paperBorder,
  );

  static ThemeData _base({
    required Color accent,
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    required Color elevated,
    required Color outline,
    bool amoled = false,
  }) {
    final isDark = brightness == Brightness.dark;
    final ink = onAccent(accent);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          surface: surface,
          onSurface: onSurface,
          surfaceContainer: elevated,
          surfaceContainerHighest: elevated,
          outline: outline,
          outlineVariant: outline,
          primary: accent,
          onPrimary: ink,
        );

    final secondary = isDark
        ? AppColors.textSecondary
        : AppColors.paperTextSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Archivo',
      textTheme: const TextTheme(
        // Display idiom — Bricolage, tight tracking (Home/History totals).
        displayLarge: AppType.hero,
        displayMedium: TextStyle(
          fontFamily: 'Bricolage',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: -1.0,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Bricolage',
          fontSize: 26,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.6,
        ),
        headlineMedium: AppType.h1,
        titleLarge: AppType.h2,
        titleMedium: TextStyle(
          fontFamily: 'Archivo',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        bodyLarge: AppType.body,
        bodyMedium: TextStyle(
          fontFamily: 'Archivo',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodySmall: AppType.bodySm,
        labelLarge: AppType.button,
        // Uppercase meta labels (SectionCard headers, 'STEPS', …).
        labelSmall: AppType.meta,
      ),
      scaffoldBackgroundColor: scaffold,
      extensions: [AmoledTokens(enabled: amoled)],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Bricolage',
          color: onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        iconTheme: IconThemeData(color: secondary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.data),
          side: BorderSide(color: outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: isDark ? 0.16 : 0.12),
        height: 64,
        labelTextStyle: WidgetStatePropertyAll(
          AppType.meta.copyWith(fontSize: 9.5, letterSpacing: 1.2),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        hintStyle: TextStyle(color: secondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(52),
          textStyle: AppType.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: AppType.button.copyWith(fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size.fromHeight(52),
          textStyle: AppType.button,
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: secondary),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      // Frosted-glass drawer: transparent panel (the page blurs behind it),
      // flat edge — no Material default grays or 16px corners.
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: surface,
        headerForegroundColor: onSurface,
        dividerColor: outline,
        weekdayStyle: AppType.metaSm.copyWith(color: secondary),
        dayStyle: AppType.dataSm.copyWith(color: onSurface),
        dayForegroundColor: WidgetStatePropertyAll(onSurface),
        todayForegroundColor: WidgetStatePropertyAll(accent),
        todayBorder: BorderSide(color: accent),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: secondary),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: accent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          side: BorderSide(color: outline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          side: BorderSide(color: outline),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: 0.6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.data),
        ),
        labelStyle: AppType.meta.copyWith(
          letterSpacing: 1.2,
          fontSize: 10,
          color: onSurface,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? elevated : const Color(0xFF1D201E),
        contentTextStyle: const TextStyle(
          fontFamily: 'Archivo',
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: elevated,
        circularTrackColor: elevated,
      ),
      // Ultra-flat: route changes are instant, no slide/fade animation.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: InstantPageTransitions(),
          TargetPlatform.iOS: InstantPageTransitions(),
          TargetPlatform.linux: InstantPageTransitions(),
          TargetPlatform.macOS: InstantPageTransitions(),
          TargetPlatform.windows: InstantPageTransitions(),
        },
      ),
    );
  }
}

/// [PageTransitionsBuilder] that swaps routes with no animation at all.
class InstantPageTransitions extends PageTransitionsBuilder {
  const InstantPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// Shared text idioms used in several places. Applied explicitly so
/// Material's own defaults — ListTiles, buttons — are untouched.
/// Colorless: compose with `color: context.…`.
abstract final class AppStyles {
  /// Section/inline titles ('Today's food', sheet titles, card headlines).
  static const title = TextStyle(
    fontFamily: 'Archivo',
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// Ordinary body copy inside cards (notes, empty-state lines).
  static const body = AppType.body;
}
