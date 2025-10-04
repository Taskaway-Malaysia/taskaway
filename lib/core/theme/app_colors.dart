import 'package:flutter/material.dart';

/// Centralized color constants for the Taskaway app
/// This ensures consistency across all screens and components
class AppColors {
  // Prevent instantiation
  AppColors._();

  // ============= Primary Colors =============
  /// Main yellow color for primary actions and branding
  static const Color primaryYellow = Color(0xFFFFDB5B);
  
  /// Darker yellow for borders and hover states
  static const Color primaryYellowDark = Color(0xFFFFC333);
  
  /// Primary black for important text and elements
  static const Color primaryBlack = Color(0xFF202020);

  // ============= Text Colors =============
  /// Main text color for headers and primary content
  static const Color textPrimary = Color(0xFF202020);
  
  /// Secondary text for descriptions and less important content
  static const Color textSecondary = Color(0xFF6B7280);
  
  /// Tertiary text for hints, placeholders, and disabled states
  static const Color textTertiary = Color(0xFF9CA3AF);
  
  /// White text for dark backgrounds
  static const Color textWhite = Colors.white;
  
  /// Light gray text for subtle elements
  static const Color textLight = Color(0xFF788494);

  // ============= Background Colors =============
  /// Main white background
  static const Color backgroundWhite = Colors.white;
  
  /// Gray background for input fields and cards
  static const Color backgroundGray = Color(0xFFF3F4F6);
  
  /// Light background for subtle sections
  static const Color backgroundLight = Color(0xFFF9FAFB);
  
  /// Very light gray for disabled states
  static const Color backgroundDisabled = Color(0xFFF5F5F5);

  // ============= Border Colors =============
  /// Default border color for inputs and cards
  static const Color borderDefault = Color(0xFFE5E7EB);
  
  /// Light border for subtle separations
  static const Color borderLight = Color(0xFFF3F4F6);
  
  /// Dark border for emphasis
  static const Color borderDark = Color(0xFFD1D5DB);

  // ============= Status Colors =============
  /// Success green for positive actions and states
  static const Color successGreen = Color(0xFF10B981);
  
  /// Light success background
  static const Color successLight = Color(0xFFD1FAE5);
  
  /// Error red for warnings and errors
  static const Color errorRed = Color(0xFFEF4444);
  
  /// Light error background
  static const Color errorLight = Color(0xFFFEE2E2);
  
  /// Warning orange for caution states
  static const Color warningOrange = Color(0xFFF59E0B);
  
  /// Light warning background
  static const Color warningLight = Color(0xFFFED7AA);
  
  /// Info blue for informational states
  static const Color infoBlue = Color(0xFF3B82F6);
  
  /// Light info background
  static const Color infoLight = Color(0xFFDBEAFE);

  // ============= Special Colors =============
  /// Star rating color
  static const Color starYellow = Color(0xFFFCC133);
  
  /// Online status green
  static const Color onlineGreen = Color(0xFF4CAF50);
  
  /// Offline status gray
  static const Color offlineGray = Color(0xFF9E9E9E);
  
  /// Shadow color
  static Color shadowColor = Colors.black.withOpacity(0.05);
  
  /// Overlay color
  static Color overlayColor = Colors.black.withOpacity(0.5);
  
  /// Black with 87% opacity (equivalent to Colors.black87)
  static const Color primaryBlack87 = Color(0xDD000000);

  // ============= Navigation Colors =============
  /// Active navigation item
  static const Color navActive = Color(0xFF202020);
  
  /// Inactive navigation item
  static const Color navInactive = Color(0xFF575656);

  // ============= Material Theme Colors =============
  /// Get MaterialColor swatch for primary yellow
  static MaterialColor get primaryYellowSwatch {
    return MaterialColor(primaryYellow.value, const {
      50: Color(0xFFFFFBEB),
      100: Color(0xFFFFF3C4),
      200: Color(0xFFFCE588),
      300: Color(0xFFFADB5F),
      400: Color(0xFFF7C948),
      500: primaryYellow,
      600: Color(0xFFE5B923),
      700: Color(0xFFC99A00),
      800: Color(0xFFA97C00),
      900: Color(0xFF8B5A00),
    });
  }
}