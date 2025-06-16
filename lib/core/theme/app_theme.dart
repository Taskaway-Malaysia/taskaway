import 'package:flutter/material.dart';
import '../constants/style_constants.dart';

/// App theme with purple for poster and orange/gold for tasker

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: StyleConstants.posterColorPrimary,
      brightness: Brightness.light,
    ),
    // Tasker color palette integration
    secondaryHeaderColor: StyleConstants.taskerColorPrimary,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: StyleConstants.taskerColorPrimary, // Using tasker primary color for buttons
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: StyleConstants.taskerColorPrimary,
        side: const BorderSide(color: StyleConstants.taskerColorPrimary),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.all(StyleConstants.defaultPadding),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        borderSide: const BorderSide(color: StyleConstants.posterColorPrimary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        borderSide: const BorderSide(color: StyleConstants.errorColor),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: StyleConstants.posterColorPrimary,
      brightness: Brightness.dark,
    ),
    // Tasker color palette integration
    secondaryHeaderColor: StyleConstants.taskerColorPrimary,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: StyleConstants.taskerColorPrimary, // Using tasker primary color for buttons
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: StyleConstants.taskerColorPrimary,
        side: const BorderSide(color: StyleConstants.taskerColorPrimary),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      contentPadding: const EdgeInsets.all(StyleConstants.defaultPadding),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        borderSide: const BorderSide(color: StyleConstants.posterColorPrimary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        borderSide: const BorderSide(color: StyleConstants.errorColor),
      ),
    ),
  );
}
