import 'package:flutter/material.dart';

/// Strict black-and-white look, matching the Aura logo.
ThemeData buildAuraTheme() {
  const black = Colors.black;
  const white = Colors.white;

  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: black,
    onPrimary: white,
    secondary: black,
    onSecondary: white,
    error: black,
    onError: white,
    surface: white,
    onSurface: black,
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: white,
    surfaceContainerLow: white,
    surfaceContainer: white,
    surfaceContainerHigh: white,
    surfaceContainerHighest: white,
    outline: black,
    outlineVariant: Color(0xFFDDDDDD),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: white,
    dividerColor: const Color(0xFFDDDDDD),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: black,
      foregroundColor: white,
      centerTitle: false,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: black,
      contentTextStyle: TextStyle(color: white),
      actionTextColor: white,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: black),
  );
}
