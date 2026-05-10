import 'package:flutter/material.dart';

// ── Dark palette ──────────────────────────────────────────
const _primary = Color(0xFF9C89FF);
const _bg = Color(0xFF1A1423);
const _surface = Color(0xFF1E1F38);
const _card = Color(0xFF231B32);
const _textMain = Color(0xFFF3F1EB);

// ── Light palette ─────────────────────────────────────────
const _lightBg = Color(0xFFF4F1FF);
const _lightSurface = Color(0xFFEBE5FF);
const _lightCard = Color(0xFFFFFFFF);
const _lightText = Color(0xFF1A1423);

// ── BuildContext theme extensions ─────────────────────────

extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get appBg => isDark ? _bg : _lightBg;
  Color get appSurface => isDark ? _surface : _lightSurface;
  Color get appCard => isDark ? _card : _lightCard;
  Color get appTextMain => isDark ? _textMain : _lightText;

  // Secondary text / icon colors
  Color get appHint => isDark ? Colors.white38 : Colors.black38;
  Color get appSubtext => isDark ? Colors.white54 : Colors.black54;
  Color get appDim => isDark ? Colors.white24 : Colors.black26;
  Color get appMuted => isDark ? Colors.white12 : Colors.black12;
  Color get appWhisper =>
      isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06);
}

// ── Themes ────────────────────────────────────────────────

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _bg,
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
      color: Color(0xFF2D2040),
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

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBg,
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
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Colors.black45),
      hintStyle: const TextStyle(color: Colors.black26),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFDDD6F3),
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

class AppColors {
  static const primary = _primary;
  static const bg = _bg;
  static const surface = _surface;
  static const card = _card;
  static const textMain = _textMain;
  static const penalty = Color(0xFFFF5252);
  static const siler = Color(0xFF00E676);
  static const neutral = Color(0xFF9E9E9E);
}
