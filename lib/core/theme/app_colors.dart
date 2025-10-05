import 'package:flutter/material.dart';

/// Taskaway Design System - Color Palette
///
/// A comprehensive, standardized color system following Material Design 3 principles.
/// This ensures complete UI consistency across all screens and components.
///
/// Design Philosophy:
/// - Semantic naming for clarity and maintainability
/// - Neutral palette for versatility
/// - Accessible contrast ratios (WCAG AA compliant)
/// - Single source of truth for all colors
class AppColors {
  // Prevent instantiation
  AppColors._();

  // ============= BRAND COLORS =============

  /// Primary brand color - Gold/Yellow for main actions
  /// Used for: Primary buttons, key CTAs, active states
  static const Color primary = Color(0xFFFFDB5B);

  /// Dark variant of primary - for hover and pressed states
  static const Color primaryDark = Color(0xFFE5C34F);

  /// Light variant of primary - for backgrounds and highlights
  static const Color primaryLight = Color(0xFFFFE896);

  /// Extra light primary - for subtle backgrounds
  static const Color primaryExtraLight = Color(0xFFFFF6D9);

  /// Accent color - Purple for secondary actions
  /// Used for: Secondary elements, alternate CTAs, highlights
  static const Color accent = Color(0xFF7773D2);

  /// Dark variant of accent
  static const Color accentDark = Color(0xFF5F5BB8);

  /// Light variant of accent
  static const Color accentLight = Color(0xFFB3AFF1);

  /// Extra light accent - for subtle backgrounds
  static const Color accentExtraLight = Color(0xFFE7E5FC);

  // ============= NEUTRAL COLORS (Gray Scale) =============

  /// Pure black - Use sparingly for maximum contrast
  static const Color black = Color(0xFF000000);

  /// Pure white - Primary background color
  static const Color white = Color(0xFFFFFFFF);

  /// Gray 950 - Darkest gray, almost black
  static const Color gray950 = Color(0xFF0A0A0A);

  /// Gray 900 - Very dark gray
  static const Color gray900 = Color(0xFF1A1A1A);

  /// Gray 800 - Dark gray, primary text color
  static const Color gray800 = Color(0xFF202020);

  /// Gray 700 - Medium-dark gray
  static const Color gray700 = Color(0xFF404040);

  /// Gray 600 - Medium gray, secondary text
  static const Color gray600 = Color(0xFF6B7280);

  /// Gray 500 - Mid-tone gray
  static const Color gray500 = Color(0xFF788494);

  /// Gray 400 - Light-medium gray, tertiary text
  static const Color gray400 = Color(0xFF9CA3AF);

  /// Gray 300 - Light gray, disabled text
  static const Color gray300 = Color(0xFFD1D5DB);

  /// Gray 200 - Very light gray, borders
  static const Color gray200 = Color(0xFFE5E7EB);

  /// Gray 100 - Extra light gray, input backgrounds
  static const Color gray100 = Color(0xFFF3F4F6);

  /// Gray 50 - Almost white, subtle backgrounds
  static const Color gray50 = Color(0xFFF9FAFB);

  /// Gray 25 - Barely visible, lightest background
  static const Color gray25 = Color(0xFFFCFCFD);

  // ============= SEMANTIC TEXT COLORS =============

  /// Primary text - Headings, important content (Gray 800)
  static const Color textPrimary = gray800;

  /// Secondary text - Body text, descriptions (Gray 600)
  static const Color textSecondary = gray600;

  /// Tertiary text - Hints, captions, subtle info (Gray 400)
  static const Color textTertiary = gray400;

  /// Disabled text - Inactive elements (Gray 300)
  static const Color textDisabled = gray300;

  /// Inverted text - Text on dark backgrounds (White)
  static const Color textInverted = white;

  /// White text - Text on colored backgrounds (White)
  static const Color textWhite = white;

  /// Link text - Clickable links (Primary)
  static const Color textLink = primary;

  /// Error text - Error messages (Error)
  static const Color textError = Color(0xFFDC2626);

  /// Success text - Success messages (Success)
  static const Color textSuccess = Color(0xFF059669);

  /// Text primary with 87% opacity - High emphasis text
  static const Color textPrimary87 = Color(0xDE202020);

  // ============= SEMANTIC BACKGROUND COLORS =============

  /// Primary background - Main screen background (White)
  static const Color backgroundPrimary = white;

  /// Secondary background - Cards, elevated surfaces (Gray 50)
  static const Color backgroundSecondary = gray50;

  /// Tertiary background - Input fields, subtle sections (Gray 100)
  static const Color backgroundTertiary = gray100;

  /// Disabled background - Inactive elements (Gray 100)
  static const Color backgroundDisabled = gray100;

  /// Hover background - Interactive element hover state (Gray 50)
  static const Color backgroundHover = gray50;

  /// Overlay background - Modal overlays (Black with opacity)
  static Color backgroundOverlay = black.withValues(alpha: 0.5);

  /// Toast background - Notification backgrounds (Gray 900)
  static const Color backgroundToast = gray900;

  // ============= SEMANTIC BORDER COLORS =============

  /// Default border - Standard borders (Gray 200)
  static const Color borderDefault = gray200;

  /// Light border - Subtle separators (Gray 100)
  static const Color borderLight = gray100;

  /// Medium border - Emphasized borders (Gray 300)
  static const Color borderMedium = gray300;

  /// Dark border - Strong borders (Gray 400)
  static const Color borderDark = gray400;

  /// Focus border - Input focus state (Primary)
  static const Color borderFocus = primary;

  /// Error border - Error state (Error)
  static const Color borderError = Color(0xFFEF4444);

  /// Success border - Success state (Success)
  static const Color borderSuccess = Color(0xFF10B981);

  // ============= STATUS COLORS =============

  /// Success - Positive actions, completed states
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successExtraLight = Color(0xFFECFDF5);

  /// Error - Errors, destructive actions, alerts
  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorExtraLight = Color(0xFFFEF2F2);

  /// Warning - Caution, important notices
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFED7AA);
  static const Color warningExtraLight = Color(0xFFFEF3C7);

  /// Info - Informational messages, tips
  static const Color info = Color(0xFF3B82F6);
  static const Color infoDark = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoExtraLight = Color(0xFFEFF6FF);

  // ============= SPECIAL UI COLORS =============

  /// Star rating color - Yellow
  static const Color star = Color(0xFFFCC133);

  /// Online status - Green indicator
  static const Color statusOnline = Color(0xFF10B981);

  /// Offline status - Gray indicator
  static const Color statusOffline = Color(0xFF9CA3AF);

  /// Away status - Yellow indicator
  static const Color statusAway = Color(0xFFF59E0B);

  /// Busy status - Red indicator
  static const Color statusBusy = Color(0xFFEF4444);

  /// Shadow color - For elevations and depth
  static Color shadow = black.withValues(alpha: 0.1);

  /// Light shadow - Subtle elevation
  static Color shadowLight = black.withValues(alpha: 0.05);

  /// Strong shadow - Prominent elevation
  static Color shadowStrong = black.withValues(alpha: 0.15);

  // ============= NAVIGATION COLORS =============

  /// Active navigation item - Selected state (Gray 800)
  static const Color navActive = gray800;

  /// Inactive navigation item - Unselected state (Gray 500)
  static const Color navInactive = gray500;

  /// Navigation background - Bottom nav background (White)
  static const Color navBackground = white;

  /// Navigation indicator - Active tab indicator (Primary)
  static const Color navIndicator = primary;

  // ============= ROLE-BASED COLORS =============

  /// Poster primary color - Purple for poster-related UI
  static const Color posterPrimary = Color(0xFF6C5CE7);

  /// Poster primary light - Light purple for backgrounds
  static const Color posterLight = Color(0xFFEFEEFC);

  /// Poster primary extra light - Extra light purple
  static const Color posterExtraLight = Color(0xFFF8F7FE);

  /// Tasker primary color - Orange for tasker-related UI
  static const Color taskerPrimary = Color(0xFFF39C12);

  /// Tasker primary light - Light orange for backgrounds
  static const Color taskerLight = Color(0xFFFEF9E7);

  /// Tasker primary extra light - Extra light orange
  static const Color taskerExtraLight = Color(0xFFFFFCF5);

  /// General purple - Used for various UI elements
  static const Color purple = Color(0xFF7B61FF);

  /// Purple light - Light variant
  static const Color purpleLight = Color(0xFFE7E1FF);

  /// Orange - For highlights and accents
  static const Color orange = Color(0xFFFDAB2F);

  /// Orange light - Light variant
  static const Color orangeLight = Color(0xFFFFF3D9);

  // ============= LEGACY SUPPORT (Deprecated) =============
  // These are kept for backward compatibility and will be removed in future versions

  @Deprecated('Use AppColors.primary instead')
  static const Color primaryYellow = Color(0xFFFFDB5B);

  @Deprecated('Use AppColors.primaryDark instead')
  static const Color primaryYellowDark = Color(0xFFFFC333);

  @Deprecated('Use AppColors.gray800 instead')
  static const Color primaryBlack = gray800;

  @Deprecated('Use AppColors.textSecondary instead')
  static const Color textLight = gray500;

  @Deprecated('Use AppColors.backgroundPrimary instead')
  static const Color backgroundWhite = white;

  @Deprecated('Use AppColors.backgroundTertiary instead')
  static const Color backgroundGray = gray100;

  @Deprecated('Use AppColors.backgroundSecondary instead')
  static const Color backgroundLight = gray50;

  @Deprecated('Use AppColors.success instead')
  static const Color successGreen = success;

  @Deprecated('Use AppColors.error instead')
  static const Color errorRed = error;

  @Deprecated('Use AppColors.warning instead')
  static const Color warningOrange = warning;

  @Deprecated('Use AppColors.info instead')
  static const Color infoBlue = info;

  @Deprecated('Use AppColors.star instead')
  static const Color starYellow = star;

  @Deprecated('Use AppColors.statusOnline instead')
  static const Color onlineGreen = statusOnline;

  @Deprecated('Use AppColors.statusOffline instead')
  static const Color offlineGray = statusOffline;

  @Deprecated('Use AppColors.shadow instead')
  static Color shadowColor = shadow;

  @Deprecated('Use AppColors.backgroundOverlay instead')
  static Color overlayColor = backgroundOverlay;

  @Deprecated('Use AppColors.gray800 with opacity instead')
  static const Color primaryBlack87 = Color(0xDD000000);

  // ============= MATERIAL COLOR SWATCH =============

  /// Material color swatch for primary color
  static MaterialColor get primarySwatch {
    return MaterialColor(primary.value, const {
      50: primaryExtraLight,
      100: primaryLight,
      200: Color(0xFFF7CB70),
      300: Color(0xFFF3B84E),
      400: Color(0xFFEFA83C),
      500: primary,
      600: primaryDark,
      700: Color(0xFFB8740F),
      800: Color(0xFF9E6000),
      900: Color(0xFF7A4A00),
    });
  }

  /// Material color swatch for accent color
  static MaterialColor get accentSwatch {
    return MaterialColor(accent.value, const {
      50: accentExtraLight,
      100: accentLight,
      200: Color(0xFF9D99E5),
      300: Color(0xFF8985DB),
      400: Color(0xFF7F7BD6),
      500: accent,
      600: accentDark,
      700: Color(0xFF4A47A0),
      800: Color(0xFF38368A),
      900: Color(0xFF282670),
    });
  }
}