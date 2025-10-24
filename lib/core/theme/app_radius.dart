import 'package:flutter/material.dart';

/// Taskaway Design System - Border Radius Constants
///
/// Standardized border radius values for consistent rounded corners throughout the app.
/// Following Material Design 3 principles with a clear hierarchy of roundness.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: AppRadius.medium,
///   ),
/// )
/// ```
class AppRadius {
  // Prevent instantiation
  AppRadius._();

  // ============= BORDER RADIUS VALUES =============

  /// No radius - Sharp corners (0px)
  static const BorderRadius none = BorderRadius.zero;

  /// Extra small radius - Minimal roundness (2px)
  /// Use for: Subtle rounding, tight spaces
  static const BorderRadius xs = BorderRadius.all(Radius.circular(2));

  /// Small radius - Slight rounding (4px)
  /// Use for: Small buttons, chips, badges
  static const BorderRadius sm = BorderRadius.all(Radius.circular(4));

  /// Small-medium radius - Common for compact elements (6px)
  /// Use for: Input fields, small cards, compact buttons
  static const BorderRadius smMd = BorderRadius.all(Radius.circular(6));

  /// Medium radius - Default for most components (8px)
  /// Use for: Cards, buttons, containers, most UI elements
  static const BorderRadius md = BorderRadius.all(Radius.circular(8));

  /// Medium-large radius - Emphasized rounding (10px)
  /// Use for: Highlighted cards, featured buttons
  static const BorderRadius mdLg = BorderRadius.all(Radius.circular(10));

  /// Large radius - Prominent rounding (12px)
  /// Use for: Large cards, modals, prominent containers
  static const BorderRadius lg = BorderRadius.all(Radius.circular(12));

  /// Extra large radius - Very rounded (16px)
  /// Use for: Hero elements, special containers
  static const BorderRadius xl = BorderRadius.all(Radius.circular(16));

  /// 2X large radius - Heavily rounded (20px)
  /// Use for: Avatars, circular-ish elements
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(20));

  /// 3X large radius - Almost circular (24px)
  /// Use for: Large avatars, pill-shaped elements
  static const BorderRadius xxxl = BorderRadius.all(Radius.circular(24));

  /// Full radius - Completely circular/pill (100px)
  /// Use for: Pills, fully rounded buttons
  static const BorderRadius full = BorderRadius.all(Radius.circular(100));

  // ============= COMMON NUMERIC VALUES (for backward compatibility) =============

  /// Radius value: 2px
  static const double radius2 = 2;

  /// Radius value: 4px
  static const double radius4 = 4;

  /// Radius value: 6px
  static const double radius6 = 6;

  /// Radius value: 8px
  static const double radius8 = 8;

  /// Radius value: 10px
  static const double radius10 = 10;

  /// Radius value: 12px
  static const double radius12 = 12;

  /// Radius value: 16px
  static const double radius16 = 16;

  /// Radius value: 20px
  static const double radius20 = 20;

  /// Radius value: 24px
  static const double radius24 = 24;

  /// Radius value: 100px (full/pill)
  static const double radius100 = 100;

  // ============= HELPER METHODS =============

  /// Create a circular border radius from a value
  static BorderRadius circular(double radius) {
    return BorderRadius.circular(radius);
  }

  /// Create a border radius with only top corners rounded
  static BorderRadius onlyTop(double radius) {
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );
  }

  /// Create a border radius with only bottom corners rounded
  static BorderRadius onlyBottom(double radius) {
    return BorderRadius.only(
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
  }

  /// Create a border radius with only left corners rounded
  static BorderRadius onlyLeft(double radius) {
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      bottomLeft: Radius.circular(radius),
    );
  }

  /// Create a border radius with only right corners rounded
  static BorderRadius onlyRight(double radius) {
    return BorderRadius.only(
      topRight: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
  }

  // ============= SEMANTIC NAMES =============

  /// Button radius - Standard for buttons (6px)
  static const BorderRadius button = smMd;

  /// Card radius - Standard for cards (8px)
  static const BorderRadius card = md;

  /// Input radius - Standard for inputs (6px)
  static const BorderRadius input = smMd;

  /// Dialog radius - Standard for dialogs (12px)
  static const BorderRadius dialog = lg;

  /// Sheet radius - Bottom sheets and modals (12px top only)
  static BorderRadius get sheet => onlyTop(radius12);

  /// Avatar radius - Fully circular (100px)
  static const BorderRadius avatar = full;

  /// Badge radius - Small pills (20px)
  static const BorderRadius badge = xxl;

  /// Chip radius - Small rounded (6px)
  static const BorderRadius chip = smMd;
}
