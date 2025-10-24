import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// Taskaway Design System - Theme Configuration
///
/// Comprehensive Material 3 theme using the Taskaway design system.
/// Ensures consistent styling across all screens and components.
class AppTheme {
  AppTheme._();

  // ============= LIGHT THEME =============

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    // Color Scheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.gray900,
      secondary: AppColors.accent,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.accentLight,
      onSecondaryContainer: AppColors.gray900,
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.errorDark,
      surface: AppColors.backgroundPrimary,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.backgroundSecondary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderDefault,
      outlineVariant: AppColors.borderLight,
      shadow: AppColors.shadow,
      brightness: Brightness.light,
    ),

    // Typography
    fontFamily: AppTypography.fontFamily,
    textTheme: TextTheme(
      // Display styles
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.displayMedium,
      displaySmall: AppTypography.displaySmall,

      // Headline styles
      headlineLarge: AppTypography.headlineLarge,
      headlineMedium: AppTypography.headlineMedium,
      headlineSmall: AppTypography.headlineSmall,

      // Title styles
      titleLarge: AppTypography.titleLarge,
      titleMedium: AppTypography.titleMedium,
      titleSmall: AppTypography.titleSmall,

      // Body styles
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,

      // Label styles
      labelLarge: AppTypography.labelLarge,
      labelMedium: AppTypography.labelMedium,
      labelSmall: AppTypography.labelSmall,
    ),

    // App Bar Theme
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: AppSpacing.appBarElevation,
      scrolledUnderElevation: AppSpacing.elevation2,
      backgroundColor: AppColors.backgroundPrimary,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppSpacing.iconLg,
      ),
      titleTextStyle: AppTypography.headlineSmall,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),

    // Scaffold Background
    scaffoldBackgroundColor: AppColors.backgroundPrimary,

    // Card Theme
    cardTheme: CardThemeData(
      elevation: AppSpacing.elevation1,
      color: AppColors.backgroundPrimary,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.borderLight),
      ),
      margin: EdgeInsets.all(AppSpacing.cardMargin),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.backgroundDisabled,
        disabledForegroundColor: AppColors.textDisabled,
        elevation: AppSpacing.elevation0,
        shadowColor: AppColors.shadow,
        minimumSize: Size(double.infinity, AppSpacing.buttonHeightLg),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.buttonPaddingHorizontal,
          vertical: AppSpacing.buttonPaddingVertical,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        textStyle: AppTypography.buttonPrimary,
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        disabledForegroundColor: AppColors.textDisabled,
        side: const BorderSide(color: AppColors.borderDefault, width: 1.5),
        minimumSize: Size(double.infinity, AppSpacing.buttonHeightLg),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.buttonPaddingHorizontal,
          vertical: AppSpacing.buttonPaddingVertical,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        textStyle: AppTypography.buttonSecondary,
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.textDisabled,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        textStyle: AppTypography.buttonText,
      ),
    ),

    // Icon Button Theme
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        disabledForegroundColor: AppColors.textDisabled,
        iconSize: AppSpacing.iconLg,
        padding: EdgeInsets.all(AppSpacing.sm),
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: AppSpacing.elevation3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundTertiary,
      hintStyle: AppTypography.inputHint,
      labelStyle: AppTypography.inputLabel,
      errorStyle: AppTypography.inputError,
      helperStyle: AppTypography.inputHelper,
      contentPadding: EdgeInsets.all(AppSpacing.inputPadding),

      // Border styles
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.borderFocus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.borderError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.borderError, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.backgroundSecondary,
      deleteIconColor: AppColors.textSecondary,
      disabledColor: AppColors.backgroundDisabled,
      selectedColor: AppColors.primaryLight,
      secondarySelectedColor: AppColors.accentLight,
      labelPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.chipPaddingHorizontal,
        vertical: AppSpacing.chipPaddingVertical,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      labelStyle: AppTypography.labelSmall,
      secondaryLabelStyle: AppTypography.labelSmall,
      brightness: Brightness.light,
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.backgroundPrimary,
      elevation: AppSpacing.elevation6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      titleTextStyle: AppTypography.headlineMedium,
      contentTextStyle: AppTypography.bodyMedium,
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.backgroundPrimary,
      elevation: AppSpacing.elevation8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXl),
          topRight: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      modalElevation: AppSpacing.elevation8,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.navBackground,
      selectedItemColor: AppColors.navActive,
      unselectedItemColor: AppColors.navInactive,
      selectedLabelStyle: AppTypography.navActive,
      unselectedLabelStyle: AppTypography.navInactive,
      type: BottomNavigationBarType.fixed,
      elevation: AppSpacing.bottomNavElevation,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    // Navigation Bar Theme (Material 3)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.navBackground,
      indicatorColor: AppColors.primaryLight,
      elevation: AppSpacing.bottomNavElevation,
      height: AppSpacing.bottomNavHeight,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTypography.navActive;
        }
        return AppTypography.navInactive;
      }),
    ),

    // Tab Bar Theme
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: AppTypography.labelMedium,
      unselectedLabelStyle: AppTypography.labelMedium,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: AppColors.primary,
          width: AppSpacing.tabIndicatorHeight,
        ),
      ),
    ),

    // Divider Theme
    dividerTheme: DividerThemeData(
      color: AppColors.borderLight,
      thickness: AppSpacing.dividerThickness,
      space: AppSpacing.dividerSpacing,
    ),

    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.backgroundToast,
      contentTextStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textInverted,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.backgroundTertiary,
      circularTrackColor: AppColors.backgroundTertiary,
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.white;
        }
        return AppColors.gray300;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.gray200;
      }),
    ),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.backgroundPrimary;
      }),
      checkColor: WidgetStateProperty.all(AppColors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
    ),

    // Radio Theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.gray400;
      }),
    ),

    // Slider Theme
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.gray200,
      thumbColor: AppColors.primary,
      overlayColor: AppColors.primaryLight,
      valueIndicatorColor: AppColors.primary,
      valueIndicatorTextStyle: AppTypography.labelSmall.copyWith(
        color: AppColors.white,
      ),
    ),

    // Tooltip Theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.backgroundToast,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      textStyle: AppTypography.bodySmall.copyWith(
        color: AppColors.textInverted,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    ),

    // List Tile Theme
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.listItemPadding,
        vertical: AppSpacing.sm,
      ),
      iconColor: AppColors.textSecondary,
      textColor: AppColors.textPrimary,
      titleTextStyle: AppTypography.bodyMedium,
      subtitleTextStyle: AppTypography.bodySmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    ),

    // Expansion Tile Theme
    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: AppColors.backgroundSecondary,
      collapsedBackgroundColor: AppColors.backgroundPrimary,
      iconColor: AppColors.textSecondary,
      textColor: AppColors.textPrimary,
      collapsedIconColor: AppColors.textSecondary,
      collapsedTextColor: AppColors.textPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    ),

    // Badge Theme
    badgeTheme: BadgeThemeData(
      backgroundColor: AppColors.error,
      textColor: AppColors.white,
      textStyle: AppTypography.captionSmall.copyWith(
        color: AppColors.white,
      ),
    ),
  );

  // ============= DARK THEME =============
  // Note: Dark theme uses the same design system with inverted colors

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,

    // Color Scheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.gray900,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.accentDark,
      onSecondaryContainer: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: AppColors.errorDark,
      onErrorContainer: AppColors.white,
      surface: AppColors.gray900,
      onSurface: AppColors.white,
      surfaceContainerHighest: AppColors.gray800,
      onSurfaceVariant: AppColors.gray400,
      outline: AppColors.gray700,
      outlineVariant: AppColors.gray800,
      shadow: AppColors.black,
      brightness: Brightness.dark,
    ),

    // Typography (same as light theme)
    fontFamily: AppTypography.fontFamily,
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.white),
      displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.white),
      displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.white),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.white),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.white),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.white),
      titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.white),
      titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.white),
      titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.white),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.white),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.white),
      bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.gray400),
      labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.white),
      labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.white),
      labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.white),
    ),

    // App Bar Theme
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: AppSpacing.appBarElevation,
      scrolledUnderElevation: AppSpacing.elevation2,
      backgroundColor: AppColors.gray900,
      foregroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(
        color: AppColors.white,
        size: AppSpacing.iconLg,
      ),
      titleTextStyle: AppTypography.headlineSmall.copyWith(color: AppColors.white),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    // Scaffold Background
    scaffoldBackgroundColor: AppColors.gray900,

    // Other theme properties follow the same pattern...
    // For brevity, they inherit from Material 3 defaults with dark colors
  );
}
