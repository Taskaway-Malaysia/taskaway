import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../constants/style_constants.dart';

/// iOS-focused theme configuration using Cupertino design system
class IosAppTheme {
  static ThemeData lightTheme = ThemeData.light().copyWith(
    // Use iOS system colors and design
    primaryColor: StyleConstants.primaryColor,
    scaffoldBackgroundColor: StyleConstants.systemGroupedBackground,
    colorScheme: const ColorScheme.light().copyWith(
      primary: StyleConstants.primaryColor,
      secondary: StyleConstants.taskerColorPrimary,
      error: StyleConstants.errorColor,
      background: StyleConstants.systemBackground,
      surface: StyleConstants.secondarySystemBackground,
    ),

    // iOS Typography
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: StyleConstants.largeTitleSize,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: StyleConstants.title1Size,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: StyleConstants.title2Size,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineLarge: TextStyle(
        fontSize: StyleConstants.title3Size,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: StyleConstants.headlineSize,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontSize: StyleConstants.bodySize,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontSize: StyleConstants.bodySize,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        fontSize: StyleConstants.calloutSize,
        fontWeight: FontWeight.normal,
      ),
      labelLarge: TextStyle(
        fontSize: StyleConstants.subheadSize,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: TextStyle(
        fontSize: StyleConstants.footnoteSize,
        fontWeight: FontWeight.normal,
      ),
      labelSmall: TextStyle(
        fontSize: StyleConstants.caption1Size,
        fontWeight: FontWeight.normal,
      ),
    ),

    // iOS-style App Bar (will be replaced with CupertinoNavigationBar in widgets)
    appBarTheme: AppBarTheme(
      backgroundColor: StyleConstants.systemBackground.withOpacity(0.94),
      foregroundColor: StyleConstants.label,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: StyleConstants.label,
        fontSize: StyleConstants.headlineSize,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(
        color: StyleConstants.systemBlue,
      ),
    ),

    // iOS-style buttons (using Material for compatibility)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: StyleConstants.systemBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        ),
        textStyle: const TextStyle(
          fontSize: StyleConstants.bodySize,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: StyleConstants.systemBlue,
        side: BorderSide(color: StyleConstants.systemBlue),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        ),
        textStyle: const TextStyle(
          fontSize: StyleConstants.bodySize,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: StyleConstants.systemBlue,
        textStyle: const TextStyle(
          fontSize: StyleConstants.bodySize,
          fontWeight: FontWeight.w400,
        ),
      ),
    ),

    // iOS-style input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: StyleConstants.secondarySystemBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: StyleConstants.defaultPadding,
        vertical: 12,
      ),
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
        borderSide: BorderSide(
          color: StyleConstants.systemBlue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        borderSide: BorderSide(
          color: StyleConstants.systemRed,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        borderSide: BorderSide(
          color: StyleConstants.systemRed,
          width: 2,
        ),
      ),
      hintStyle: TextStyle(
        color: StyleConstants.tertiaryLabel,
        fontSize: StyleConstants.bodySize,
      ),
      labelStyle: TextStyle(
        color: StyleConstants.secondaryLabel,
        fontSize: StyleConstants.bodySize,
      ),
    ),

    // iOS-style cards
    cardTheme: const CardThemeData(
      color: StyleConstants.secondarySystemBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(StyleConstants.defaultRadius)),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: StyleConstants.defaultPadding,
        vertical: StyleConstants.smallPadding,
      ),
    ),

    // iOS dividers
    dividerTheme: DividerThemeData(
      color: StyleConstants.systemGray4,
      thickness: 0.5,
      space: 0,
    ),

    // iOS list tiles
    listTileTheme: ListTileThemeData(
      tileColor: StyleConstants.secondarySystemBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: StyleConstants.defaultPadding,
        vertical: StyleConstants.smallPadding,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: StyleConstants.primaryColor,
    scaffoldBackgroundColor: CupertinoColors.black,
    colorScheme: const ColorScheme.dark().copyWith(
      primary: StyleConstants.primaryColor,
      secondary: StyleConstants.taskerColorPrimary,
      error: StyleConstants.errorColor,
      background: CupertinoColors.black,
      surface: CupertinoColors.darkBackgroundGray,
    ),

    // Dark mode typography
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: StyleConstants.largeTitleSize,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: CupertinoColors.white,
      ),
      displayMedium: TextStyle(
        fontSize: StyleConstants.title1Size,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: CupertinoColors.white,
      ),
      displaySmall: TextStyle(
        fontSize: StyleConstants.title2Size,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: CupertinoColors.white,
      ),
      headlineLarge: TextStyle(
        fontSize: StyleConstants.title3Size,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: CupertinoColors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: StyleConstants.headlineSize,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.white,
      ),
      titleLarge: TextStyle(
        fontSize: StyleConstants.bodySize,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: StyleConstants.bodySize,
        fontWeight: FontWeight.normal,
        color: CupertinoColors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: StyleConstants.calloutSize,
        fontWeight: FontWeight.normal,
        color: CupertinoColors.white,
      ),
      labelLarge: TextStyle(
        fontSize: StyleConstants.subheadSize,
        fontWeight: FontWeight.w500,
        color: CupertinoColors.white,
      ),
      bodySmall: TextStyle(
        fontSize: StyleConstants.footnoteSize,
        fontWeight: FontWeight.normal,
        color: CupertinoColors.systemGrey,
      ),
      labelSmall: TextStyle(
        fontSize: StyleConstants.caption1Size,
        fontWeight: FontWeight.normal,
        color: CupertinoColors.systemGrey2,
      ),
    ),

    // Dark mode app bar
    appBarTheme: AppBarTheme(
      backgroundColor: CupertinoColors.darkBackgroundGray.withOpacity(0.94),
      foregroundColor: CupertinoColors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: CupertinoColors.white,
        fontSize: StyleConstants.headlineSize,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(
        color: StyleConstants.systemBlue,
      ),
    ),

    // Dark mode buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: StyleConstants.systemBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StyleConstants.defaultRadius),
        ),
      ),
    ),

    // Dark mode input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CupertinoColors.darkBackgroundGray,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: StyleConstants.defaultPadding,
        vertical: 12,
      ),
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
        borderSide: BorderSide(
          color: StyleConstants.systemBlue,
          width: 2,
        ),
      ),
      hintStyle: TextStyle(
        color: CupertinoColors.systemGrey,
        fontSize: StyleConstants.bodySize,
      ),
      labelStyle: TextStyle(
        color: CupertinoColors.systemGrey2,
        fontSize: StyleConstants.bodySize,
      ),
    ),

    // Dark mode cards
    cardTheme: const CardThemeData(
      color: CupertinoColors.darkBackgroundGray,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(StyleConstants.defaultRadius)),
      ),
    ),

    // Dark mode dividers
    dividerTheme: DividerThemeData(
      color: CupertinoColors.systemGrey4.darkColor,
      thickness: 0.5,
      space: 0,
    ),
  );
}