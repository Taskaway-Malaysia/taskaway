import 'package:flutter/material.dart';

/// Constants related to styling and UI
class StyleConstants {
  // App Name
  static const String appName = 'Taskaway Malaysia';
  
  // Colors - Poster palette (purple)
  static const Color posterColorPrimary = Color(0xFF7773D2);
  static const Color posterColorSecondary = Color(0xFFB3AFF1);
  static const Color posterColorLight = Color(0xFFE7E5FC);
  
  // Colors - Tasker palette (orange/gold)
  static const Color taskerColorPrimary = Color(0xFFEB9F2F);
  static const Color taskerColorSecondary = Color(0xFFF9D281);
  static const Color taskerColorLight = Color(0xFFFEF4D5);
  
  // System colors
  static const Color primaryColor = posterColorPrimary; // Default primary is poster color
  static const Color secondaryColor = Color(0xFF64748B);
  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF16A34A);
  
  // Spacing
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  
  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
