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

/// Kinetic design tokens — minimalist, dark by default.
abstract final class AppColors {
  // Surfaces
  static const background = Color(0xFF0B0C0F);
  static const surface = Color(0xFF15171C);
  static const surfaceElevated = Color(0xFF1E2128);
  static const border = Color(0xFF2A2E37);

  // AMOLED true-black surfaces (dark brightness only) — pure-black
  // background plus near-black card/input layers that still separate.
  static const amoledBackground = Color(0xFF000000);
  static const amoledSurface = Color(0xFF0A0B0D);
  static const amoledElevated = Color(0xFF141619);
  static const amoledBorder = Color(0xFF232529);

  // Text
  static const textPrimary = Color(0xFFF2F4F8);
  static const textSecondary = Color(0xFF9AA1AE);
  static const textTertiary = Color(0xFF6B7280);

  // Brand & data
  static const accent = Color(0xFF22D3A5); // kinetic teal
  static const accentDim = Color(0xFF17614E);
  static const heatHot = Color(0xFFE53935); // freshly trained
  static const heatWarm = Color(0xFFEF8354);
  static const heatRest = Color(0xFF4A4A4A); // recovering
  static const heatCold = Color(0xFF4A4A4A); // untrained

  /// Destructive-action tint (Round 9): one token for discard/danger
  /// confirmations — replaces the ad-hoc `Colors.redAccent` usages that
  /// previously split into two different reds.
  static const danger = Color(0xFFE53935);

  // Grades
  static const gradeS = Color(0xFFFFC94D);
  static const gradeA = Color(0xFF66BB6A);
  static const gradeB = Color(0xFF42A5F5);
  static const gradeC = Color(0xFFABBC5A);
  static const gradeD = Color(0xFFEF8354);
  static const gradeF = Color(0xFF8A8F98);

  static Color gradeColor(String grade) => switch (grade) {
        'S' => gradeS,
        'A' => gradeA,
        'B' => gradeB,
        'C' => gradeC,
        'D' => gradeD,
        _ => gradeF,
      };
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
/// statics so light mode gets readable values while dark stays exactly the
/// constants above — unless AMOLED black is on, where surfaces swap to the
/// true-black variants. Each mapping mirrors its colorScheme counterpart
/// (onSurface / surface / surfaceContainer / outline / scaffoldBackground),
/// which [AppTheme] seeds from the same numbers for dark.
extension AppColorsContext on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  /// True only in dark brightness with the AMOLED toggle on.
  bool get _amoled =>
      _isDark &&
      (Theme.of(this).extension<AmoledTokens>()?.enabled ?? false);

  Color get textPrimary =>
      _isDark ? AppColors.textPrimary : const Color(0xFF14161A);
  Color get textSecondary =>
      _isDark ? AppColors.textSecondary : const Color(0xFF4E5666);
  Color get textTertiary =>
      _isDark ? AppColors.textTertiary : const Color(0xFF818899);
  Color get surface => _amoled
      ? AppColors.amoledSurface
      : _isDark
          ? AppColors.surface
          : Colors.white;
  Color get surfaceElevated => _amoled
      ? AppColors.amoledElevated
      : _isDark
          ? AppColors.surfaceElevated
          : const Color(0xFFF0F1F4);
  Color get background => _amoled
      ? AppColors.amoledBackground
      : _isDark
          ? AppColors.background
          : const Color(0xFFF6F7F9);
  Color get border => _amoled
      ? AppColors.amoledBorder
      : _isDark
          ? AppColors.border
          : const Color(0xFFE1E4EA);

  /// App-wide danger tint; light mode darkens for contrast.
  Color get danger =>
      _isDark ? AppColors.danger : const Color(0xFFB71C1C);

  /// The user-selected accent (Round 9.2) — resolved from the seeded
  /// color scheme so every widget follows the Appearance palette.
  Color get accent => Theme.of(this).colorScheme.primary;

  /// Dimmed accent for backgrounds/segments that need a quieter accent.
  Color get accentDim => accent.withValues(alpha: 0.45);
}

abstract final class AppTheme {
  static ThemeData dark({
    Color accent = AppColors.accent,
    bool amoled = false,
  }) =>
      _base(
        accent: accent,
        brightness: Brightness.dark,
        scaffold: amoled ? AppColors.amoledBackground : AppColors.background,
        surface: amoled ? AppColors.amoledSurface : AppColors.surface,
        onSurface: AppColors.textPrimary,
        amoled: amoled,
      );

  static ThemeData light({Color accent = AppColors.accent}) => _base(
        accent: accent,
        brightness: Brightness.light,
        scaffold: const Color(0xFFF6F7F9),
        surface: Colors.white,
        onSurface: const Color(0xFF14161A),
      );

  static ThemeData _base({
    required Color accent,
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    bool amoled = false,
  }) {
    final isDark = brightness == Brightness.dark;
    final ink = onAccent(accent);
    // Dark-branch surfaces — swapped for the AMOLED variants when active;
    // light values are spelled out per-site below to keep exact parity.
    final darkElev =
        amoled ? AppColors.amoledElevated : AppColors.surfaceElevated;
    final darkBorder = amoled ? AppColors.amoledBorder : AppColors.border;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      surface: surface,
      onSurface: onSurface,
      surfaceContainer: isDark ? darkElev : const Color(0xFFF0F1F4),
      outline: isDark ? darkBorder : const Color(0xFFE1E4EA),
      primary: accent,
      onPrimary: ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      // Partial text theme: only the styles the app's own idioms target.
      // Unfilled entries stay Material's M3 defaults so ListTiles, buttons
      // etc. keep the look they shipped with.
      textTheme: const TextTheme(
        // Stat values (Home strip, workout totals): the 24 px display idiom.
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.15,
          letterSpacing: -0.5,
        ),
        // Uppercase captions (SectionCard headers, 'STEPS', 'WATER', …).
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
      scaffoldBackgroundColor: scaffold,
      extensions: [AmoledTokens(enabled: amoled)],
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
              color: isDark ? darkBorder : const Color(0xFFE7E9EE)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor:
            accent.withValues(alpha: isDark ? 0.16 : 0.12),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkElev : const Color(0xFFF0F1F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? darkBorder : const Color(0xFFE7E9EE),
        thickness: 1,
      ),
      // Frosted-glass drawer: transparent panel (the page blurs behind it),
      // flat edge — no Material default grays or 16px corners.
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      dialogTheme: DialogThemeData(
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
              color: isDark ? darkBorder : const Color(0xFFE7E9EE)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
              color: isDark ? darkBorder : const Color(0xFFE7E9EE)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? darkElev : const Color(0xFF1D2026),
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
  ) =>
      child;
}

/// Shared text idioms used in several places (Round 9 polish). Applied
/// explicitly so Material's own defaults — ListTiles, buttons — are
/// untouched. Colorless: compose with `color: context.…`.
abstract final class AppStyles {
  /// Section/inline titles ('Today's food', sheet titles, card headlines).
  static const title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// Ordinary body copy inside cards (notes, empty-state lines).
  static const body = TextStyle(
    fontSize: 14.5,
    height: 1.35,
  );
}
