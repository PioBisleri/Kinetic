import 'package:flutter/material.dart';

/// Kinetic design tokens — minimalist, dark by default.
abstract final class AppColors {
  // Surfaces
  static const background = Color(0xFF0B0C0F);
  static const surface = Color(0xFF15171C);
  static const surfaceElevated = Color(0xFF1E2128);
  static const border = Color(0xFF2A2E37);

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

/// Theme-bound accessors for the semantic palette above.
///
/// Widget code reads these as `context.textPrimary` etc. instead of the
/// statics so light mode gets readable values while dark stays exactly the
/// constants above. Each mapping mirrors its colorScheme counterpart
/// (onSurface / surface / surfaceContainer / outline / scaffoldBackground),
/// which [AppTheme] seeds from the same numbers for dark.
extension AppColorsContext on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get textPrimary =>
      _isDark ? AppColors.textPrimary : const Color(0xFF14161A);
  Color get textSecondary =>
      _isDark ? AppColors.textSecondary : const Color(0xFF4E5666);
  Color get textTertiary =>
      _isDark ? AppColors.textTertiary : const Color(0xFF818899);
  Color get surface => _isDark ? AppColors.surface : Colors.white;
  Color get surfaceElevated =>
      _isDark ? AppColors.surfaceElevated : const Color(0xFFF0F1F4);
  Color get background =>
      _isDark ? AppColors.background : const Color(0xFFF6F7F9);
  Color get border => _isDark ? AppColors.border : const Color(0xFFE1E4EA);
}

abstract final class AppTheme {
  static ThemeData get dark => _base(
        brightness: Brightness.dark,
        scaffold: AppColors.background,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      );

  static ThemeData get light => _base(
        brightness: Brightness.light,
        scaffold: const Color(0xFFF6F7F9),
        surface: Colors.white,
        onSurface: const Color(0xFF14161A),
      );

  static ThemeData _base({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
    ).copyWith(
      surface: surface,
      onSurface: onSurface,
      surfaceContainer: isDark ? AppColors.surfaceElevated : const Color(0xFFF0F1F4),
      outline: isDark ? AppColors.border : const Color(0xFFE1E4EA),
      primary: AppColors.accent,
      onPrimary: const Color(0xFF04211A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
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
        color: isDark ? AppColors.surface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? AppColors.border : const Color(0xFFE7E9EE)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surface : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accent.withValues(
            alpha: isDark ? 0.16 : 0.12),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceElevated : const Color(0xFFF0F1F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF04211A),
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.border : const Color(0xFFE7E9EE),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.surfaceElevated : const Color(0xFF1D2026),
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
