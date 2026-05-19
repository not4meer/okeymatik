import 'package:flutter/material.dart';

enum AppTheme { dark, light, girls }

// ── Dark palette ──────────────────────────────────────────
const _primary = Color(0xFF4A90FF);
const _bg = Color(0xFF080D18);
const _surface = Color(0xFF0E1628);
const _card = Color(0xFF152030);
const _textMain = Color(0xFFF0F4FF);

// ── Light palette ─────────────────────────────────────────
const _lightBg = Color(0xFFD8E8FF);
const _lightSurface = Color(0xFFC4D8FF);
const _lightCard = Color(0xFFFFFFFF);
const _lightText = Color(0xFF0D1F3C);

// ── Girls palette ─────────────────────────────────────────
const _girlsBg = Color(0xFF1A0D1F);
const _girlsSurface = Color(0xFF2A1030);
const _girlsCard = Color(0xFF3A1540);
const _girlsPrimary = Color(0xFFFF66C4);
const _girlsText = Color(0xFFFFF0FA);
const _girlsHint = Color(0xFFFFAADD);

// ── Theme extension (embeds AppTheme into ThemeData) ──────
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final AppTheme mode;
  const AppThemeExtension(this.mode);

  @override
  AppThemeExtension copyWith({AppTheme? mode}) =>
      AppThemeExtension(mode ?? this.mode);

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) => this;
}

// ── BuildContext theme extensions ─────────────────────────

extension AppThemeX on BuildContext {
  AppTheme get appTheme =>
      Theme.of(this).extension<AppThemeExtension>()?.mode ?? AppTheme.dark;

  bool get isDark => appTheme == AppTheme.dark;
  bool get isLight => appTheme == AppTheme.light;
  bool get isGirls => appTheme == AppTheme.girls;

  Color get appBg => switch (appTheme) {
        AppTheme.dark => _bg,
        AppTheme.light => _lightBg,
        AppTheme.girls => _girlsBg,
      };

  Color get appSurface => switch (appTheme) {
        AppTheme.dark => _surface,
        AppTheme.light => _lightSurface,
        AppTheme.girls => _girlsSurface,
      };

  Color get appCard => switch (appTheme) {
        AppTheme.dark => _card,
        AppTheme.light => _lightCard,
        AppTheme.girls => _girlsCard,
      };

  Color get appTextMain => switch (appTheme) {
        AppTheme.dark => _textMain,
        AppTheme.light => _lightText,
        AppTheme.girls => _girlsText,
      };

  Color get appPrimary => switch (appTheme) {
        AppTheme.dark => _primary,
        AppTheme.light => _primary,
        AppTheme.girls => _girlsPrimary,
      };

  Color get appHint => switch (appTheme) {
        AppTheme.dark => Colors.white38,
        AppTheme.light => Colors.black38,
        AppTheme.girls => _girlsHint.withValues(alpha: 0.65),
      };

  Color get appSubtext => switch (appTheme) {
        AppTheme.dark => Colors.white54,
        AppTheme.light => Colors.black54,
        AppTheme.girls => _girlsHint.withValues(alpha: 0.85),
      };

  Color get appDim => switch (appTheme) {
        AppTheme.dark => Colors.white24,
        AppTheme.light => Colors.black26,
        AppTheme.girls => _girlsHint.withValues(alpha: 0.35),
      };

  Color get appMuted => switch (appTheme) {
        AppTheme.dark => Colors.white12,
        AppTheme.light => Colors.black.withValues(alpha: 0.18),
        AppTheme.girls => _girlsPrimary.withValues(alpha: 0.18),
      };

  Color get appWhisper => switch (appTheme) {
        AppTheme.dark => Colors.white10,
        AppTheme.light => Colors.black.withValues(alpha: 0.06),
        AppTheme.girls => _girlsPrimary.withValues(alpha: 0.07),
      };
}

// ── Dark Theme ────────────────────────────────────────────

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _bg,
    extensions: const [AppThemeExtension(AppTheme.dark)],
    colorScheme: const ColorScheme.dark(
      primary: _primary,
      secondary: _primary,
      surface: _surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _textMain,
    ),
    cardTheme: const CardThemeData(
      color: _card,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _bg,
      foregroundColor: _textMain,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _textMain,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _surface,
      modalBackgroundColor: _surface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primary,
        side: const BorderSide(color: _primary),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Colors.white54),
      hintStyle: const TextStyle(color: Colors.white30),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF0A1830),
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: _textMain),
      bodyMedium: TextStyle(color: _textMain),
      titleLarge: TextStyle(color: _textMain, fontWeight: FontWeight.w700),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? _primary
              : Colors.transparent),
      side: const BorderSide(color: Colors.white38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: _surface),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: _card,
      contentTextStyle: TextStyle(color: _textMain),
    ),
  );
}

// ── Light Theme ───────────────────────────────────────────

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBg,
    extensions: const [AppThemeExtension(AppTheme.light)],
    colorScheme: const ColorScheme.light(
      primary: _primary,
      secondary: _primary,
      surface: _lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _lightText,
      surfaceContainerHighest: _lightCard,
    ),
    cardTheme: const CardThemeData(
      color: _lightCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shadowColor: Colors.transparent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBg,
      foregroundColor: _lightText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _lightText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: _lightText),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _lightSurface,
      modalBackgroundColor: _lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primary,
        side: const BorderSide(color: _primary),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCED6E8), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCED6E8), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Colors.black45),
      hintStyle: const TextStyle(color: Colors.black38),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFCDD8F0),
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: _lightText),
      bodyMedium: TextStyle(color: _lightText),
      titleLarge: TextStyle(color: _lightText, fontWeight: FontWeight.w700),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? _primary
              : Colors.transparent),
      side: const BorderSide(color: Colors.black38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: _lightSurface,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: _lightText,
      contentTextStyle: TextStyle(color: _lightBg),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _primary : Colors.white70),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? _primary.withValues(alpha: 0.4)
              : Colors.black12),
    ),
  );
}

// ── Girls Theme ───────────────────────────────────────────

ThemeData buildGirlsTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _girlsBg,
    extensions: const [AppThemeExtension(AppTheme.girls)],
    colorScheme: const ColorScheme.dark(
      primary: _girlsPrimary,
      secondary: _girlsPrimary,
      surface: _girlsSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _girlsText,
    ),
    cardTheme: const CardThemeData(
      color: _girlsCard,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _girlsBg,
      foregroundColor: _girlsText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _girlsText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _girlsSurface,
      modalBackgroundColor: _girlsSurface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _girlsPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _girlsPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _girlsPrimary,
        side: const BorderSide(color: _girlsPrimary),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _girlsCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _girlsPrimary, width: 1.5),
      ),
      labelStyle: TextStyle(color: _girlsHint.withValues(alpha: 0.7)),
      hintStyle: TextStyle(color: _girlsHint.withValues(alpha: 0.4)),
    ),
    dividerTheme: DividerThemeData(
      color: _girlsPrimary.withValues(alpha: 0.15),
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: _girlsText),
      bodyMedium: TextStyle(color: _girlsText),
      titleLarge: TextStyle(color: _girlsText, fontWeight: FontWeight.w700),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? _girlsPrimary
              : Colors.transparent),
      side: BorderSide(color: _girlsHint.withValues(alpha: 0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: _girlsSurface),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: _girlsCard,
      contentTextStyle: TextStyle(color: _girlsText),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _girlsPrimary : Colors.white70),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? _girlsPrimary.withValues(alpha: 0.4)
              : Colors.white12),
    ),
  );
}

// ── AppColors ─────────────────────────────────────────────

class AppColors {
  static const primary = _primary;
  static const girlsPrimary = Color(0xFFFF66C4);
  static const bg = _bg;
  static const surface = _surface;
  static const card = _card;
  static const textMain = _textMain;
  static const penalty = Color(0xFFFF5252);
  static const siler = Color(0xFF00E676);
  static const neutral = Color(0xFF9E9E9E);
  static const gold = Color(0xFFF59E0B);
}
