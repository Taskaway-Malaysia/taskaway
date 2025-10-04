import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Taskaway Design System - Typography
///
/// A comprehensive, standardized typography system for consistent text styles.
/// Based on Material Design 3 type scale with custom adjustments.
///
/// Font Family: 'Inter' (Primary, fallback to system)
///
/// Scale:
/// - Display: Extra large text for hero sections
/// - Headline: Page titles and major headings
/// - Title: Section headings and card titles
/// - Body: Main content and paragraphs
/// - Label: Buttons, tabs, and short labels
/// - Caption: Metadata and helper text
class AppTypography {
  AppTypography._();

  // ============= FONT FAMILY =============

  /// Primary font family - Inter
  static const String fontFamily = 'Inter';

  /// Fallback font family
  static const String fontFamilyFallback = 'System';

  // ============= FONT WEIGHTS =============

  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // ============= FONT SIZES =============
  // Optimized type scale for mobile-first design with perfect proportions

  static const double size10 = 10.0;  // Micro text
  static const double size11 = 11.0;  // Fine print
  static const double size12 = 12.0;  // Caption, helper text
  static const double size13 = 13.0;  // Small UI text
  static const double size14 = 14.0;  // Body text, buttons
  static const double size15 = 15.0;  // Comfortable body
  static const double size16 = 16.0;  // Large body, inputs
  static const double size18 = 18.0;  // Small headings
  static const double size20 = 20.0;  // Medium headings
  static const double size22 = 22.0;  // Large headings
  static const double size24 = 24.0;  // Extra large headings
  static const double size28 = 28.0;  // Page titles
  static const double size32 = 32.0;  // Display small
  static const double size40 = 40.0;  // Display medium
  static const double size48 = 48.0;  // Display large

  // ============= LINE HEIGHTS =============
  // Optimized for better readability and visual rhythm

  static const double lineHeightTight = 1.2;      // For headings
  static const double lineHeightSnug = 1.3;       // For large text
  static const double lineHeightNormal = 1.5;     // For body text (default)
  static const double lineHeightRelaxed = 1.6;    // For comfortable reading
  static const double lineHeightLoose = 1.75;     // For spacious layouts

  // ============= DISPLAY STYLES (Hero Text) =============
  // Optimized for impact while maintaining readability

  /// Display Large - 48px, Bold
  /// Use for: Hero sections, splash screens, marketing headlines
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: size48,
    fontWeight: bold,
    height: 1.1,  // Tighter for large displays
    color: AppColors.textPrimary,
    letterSpacing: -1.0,  // Tighter tracking for large text
  );

  /// Display Medium - 40px, Bold
  /// Use for: Large feature headings, onboarding titles
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: size40,
    fontWeight: bold,
    height: 1.15,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
  );

  /// Display Small - 32px, SemiBold
  /// Use for: Section hero text, modal titles
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: size32,
    fontWeight: semiBold,
    height: 1.2,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // ============= HEADLINE STYLES (Page Titles) =============
  // Optimized for clear hierarchy and scannability

  /// Headline Large - 28px, Bold
  /// Use for: Main page titles, important announcements
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: size28,
    fontWeight: bold,
    height: 1.25,  // Slightly more breathing room
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  /// Headline Medium - 24px, SemiBold
  /// Use for: Screen headers, dialog titles, section titles
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: size24,
    fontWeight: semiBold,
    height: 1.3,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  /// Headline Small - 22px, SemiBold
  /// Use for: Subpage titles, card headers, list headers
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: size22,
    fontWeight: semiBold,
    height: 1.3,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  // ============= TITLE STYLES (Section Headers) =============
  // Optimized for content organization and clarity

  /// Title Large - 20px, SemiBold
  /// Use for: Section headings, important list headers
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: size20,
    fontWeight: semiBold,
    height: 1.4,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  /// Title Medium - 18px, SemiBold
  /// Use for: Card titles, form sections, list headers
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: size18,
    fontWeight: semiBold,
    height: 1.4,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  /// Title Small - 16px, SemiBold
  /// Use for: Small section headers, list item titles
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: size16,
    fontWeight: semiBold,
    height: 1.4,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  // ============= BODY STYLES (Main Content) =============
  // Optimized for maximum readability and comfortable reading

  /// Body Large - 16px, Regular
  /// Use for: Main content, long-form text, important descriptions
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: size16,
    fontWeight: regular,
    height: 1.6,  // More comfortable for reading
    color: AppColors.textPrimary,
    letterSpacing: 0.15,  // Slight letter spacing for better legibility
  );

  /// Body Medium - 15px, Regular
  /// Use for: Standard body text, list items, descriptions
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: size15,
    fontWeight: regular,
    height: 1.6,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  /// Body Small - 13px, Regular
  /// Use for: Small body text, secondary information, metadata
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: size13,
    fontWeight: regular,
    height: 1.5,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  // ============= LABEL STYLES (Buttons & UI Elements) =============
  // Optimized for clarity in interactive elements

  /// Label Large - 16px, SemiBold
  /// Use for: Large buttons, primary CTAs
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: size16,
    fontWeight: semiBold,
    height: 1.2,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,  // Better tracking for buttons
  );

  /// Label Medium - 15px, Medium
  /// Use for: Standard buttons, tabs, chips
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: size15,
    fontWeight: medium,
    height: 1.2,
    color: AppColors.textPrimary,
    letterSpacing: 0.25,
  );

  /// Label Small - 13px, Medium
  /// Use for: Small buttons, badges, tags
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: size13,
    fontWeight: medium,
    height: 1.2,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  // ============= CAPTION STYLES (Helper Text) =============
  // Optimized for supporting information and metadata

  /// Caption Large - 13px, Regular
  /// Use for: Input helper text, longer captions, subtitles
  static const TextStyle captionLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: size13,
    fontWeight: regular,
    height: 1.4,
    color: AppColors.textTertiary,
    letterSpacing: 0.1,
  );

  /// Caption Medium - 12px, Regular
  /// Use for: Timestamps, metadata, card info
  static const TextStyle captionMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: size12,
    fontWeight: regular,
    height: 1.4,
    color: AppColors.textTertiary,
    letterSpacing: 0.1,
  );

  /// Caption Small - 11px, Regular
  /// Use for: Fine print, legal text, micro copy
  static const TextStyle captionSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: size11,
    fontWeight: regular,
    height: 1.4,
    color: AppColors.textTertiary,
    letterSpacing: 0.1,
  );

  // ============= SPECIALIZED STYLES =============

  /// Link Text - 15px, Medium with underline
  /// Use for: Clickable links in body text
  static const TextStyle link = TextStyle(
    fontFamily: fontFamily,
    fontSize: size15,
    fontWeight: medium,
    height: 1.6,
    color: AppColors.textLink,
    decoration: TextDecoration.underline,
    letterSpacing: 0.1,
  );

  /// Overline - 11px, Bold, Uppercase
  /// Use for: Category labels, eyebrows, section labels
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: size11,
    fontWeight: bold,
    height: 1.3,
    color: AppColors.textSecondary,
    letterSpacing: 1.2,  // Wide tracking for uppercase
  );

  /// Code - 13px, Monospace
  /// Use for: Code snippets, technical text
  static const TextStyle code = TextStyle(
    fontFamily: 'monospace',
    fontSize: size13,
    fontWeight: regular,
    height: 1.6,
    color: AppColors.textPrimary,
    backgroundColor: AppColors.backgroundTertiary,
    letterSpacing: 0,
  );

  // ============= BUTTON TEXT STYLES =============
  // Optimized for touch targets and clarity

  /// Primary Button Text - 16px, SemiBold
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: fontFamily,
    fontSize: size16,
    fontWeight: semiBold,
    height: 1.2,
    color: AppColors.textInverted,
    letterSpacing: 0.5,  // More prominent tracking for CTAs
  );

  /// Secondary Button Text - 15px, SemiBold
  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: size15,
    fontWeight: semiBold,
    height: 1.2,
    color: AppColors.textPrimary,
    letterSpacing: 0.4,
  );

  /// Text Button Text - 15px, Medium
  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: size15,
    fontWeight: medium,
    height: 1.2,
    color: AppColors.primary,
    letterSpacing: 0.2,
  );

  // ============= INPUT STYLES =============
  // Optimized for form usability and accessibility

  /// Input Text - 16px, Regular
  /// Use for: Text field input (16px for iOS zoom prevention)
  static const TextStyle input = TextStyle(
    fontFamily: fontFamily,
    fontSize: size16,
    fontWeight: regular,
    height: 1.5,
    color: AppColors.textPrimary,
    letterSpacing: 0.15,
  );

  /// Input Label - 15px, Medium
  /// Use for: Field labels
  static const TextStyle inputLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: size15,
    fontWeight: medium,
    height: 1.4,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  /// Input Hint - 16px, Regular
  /// Use for: Placeholder text
  static const TextStyle inputHint = TextStyle(
    fontFamily: fontFamily,
    fontSize: size16,
    fontWeight: regular,
    height: 1.5,
    color: AppColors.textTertiary,
    letterSpacing: 0.15,
  );

  /// Input Error - 13px, Regular
  /// Use for: Error messages below inputs
  static const TextStyle inputError = TextStyle(
    fontFamily: fontFamily,
    fontSize: size13,
    fontWeight: regular,
    height: 1.4,
    color: AppColors.textError,
    letterSpacing: 0.1,
  );

  /// Input Helper - 13px, Regular
  /// Use for: Helper text below inputs
  static const TextStyle inputHelper = TextStyle(
    fontFamily: fontFamily,
    fontSize: size13,
    fontWeight: regular,
    height: 1.4,
    color: AppColors.textTertiary,
    letterSpacing: 0.1,
  );

  // ============= NAVIGATION STYLES =============
  // Optimized for tab bars and bottom navigation

  /// Navigation Active - 11px, Bold
  static const TextStyle navActive = TextStyle(
    fontFamily: fontFamily,
    fontSize: size11,
    fontWeight: bold,
    height: 1.1,
    color: AppColors.navActive,
    letterSpacing: 0.3,
  );

  /// Navigation Inactive - 11px, Medium
  static const TextStyle navInactive = TextStyle(
    fontFamily: fontFamily,
    fontSize: size11,
    fontWeight: medium,
    height: 1.1,
    color: AppColors.navInactive,
    letterSpacing: 0.2,
  );

  // ============= LEGACY SUPPORT (Deprecated) =============

  @Deprecated('Use AppTypography.headlineLarge instead')
  static const TextStyle heading1 = headlineLarge;

  @Deprecated('Use AppTypography.headlineMedium instead')
  static const TextStyle heading2 = headlineMedium;

  @Deprecated('Use AppTypography.headlineSmall instead')
  static const TextStyle heading3 = headlineSmall;

  @Deprecated('Use AppTypography.bodyMedium instead')
  static const TextStyle body = bodyMedium;

  @Deprecated('Use AppTypography.captionMedium instead')
  static const TextStyle caption = captionMedium;
}
