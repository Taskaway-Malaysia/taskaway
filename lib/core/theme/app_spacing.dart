/// Taskaway Design System - Spacing & Layout
///
/// A comprehensive, standardized spacing system using the 4px/8px grid.
/// This ensures visual rhythm and consistency across all screens.
///
/// Philosophy:
/// - Base unit: 4px for fine-grained control
/// - Primary unit: 8px for most spacing needs
/// - All spacing values are multiples of 4
/// - Semantic naming for common use cases
class AppSpacing {
  AppSpacing._();

  // ============= BASE SPACING UNITS =============

  /// Extra extra small - 2px
  static const double xxs = 2.0;

  /// Extra small - 4px
  static const double xs = 4.0;

  /// Small - 8px
  static const double sm = 8.0;

  /// Medium - 12px
  static const double md = 12.0;

  /// Large - 16px (Most commonly used)
  static const double lg = 16.0;

  /// Extra large - 20px
  static const double xl = 20.0;

  /// Extra extra large - 24px
  static const double xxl = 24.0;

  /// Extra extra extra large - 32px
  static const double xxxl = 32.0;

  /// Huge - 40px
  static const double huge = 40.0;

  /// Extra huge - 48px
  static const double xhuge = 48.0;

  /// Massive - 64px
  static const double massive = 64.0;

  // ============= SEMANTIC SPACING (Common Use Cases) =============

  /// Screen padding - Horizontal padding for full screens (16px)
  static const double screenPaddingHorizontal = lg;

  /// Screen padding - Vertical padding for full screens (20px)
  static const double screenPaddingVertical = xl;

  /// Section spacing - Between major sections (32px)
  static const double sectionSpacing = xxxl;

  /// Card padding - Inside cards (16px)
  static const double cardPadding = lg;

  /// Card margin - Between cards (12px)
  static const double cardMargin = md;

  /// List item padding - Inside list items (16px)
  static const double listItemPadding = lg;

  /// List item spacing - Between list items (8px)
  static const double listItemSpacing = sm;

  /// Button padding horizontal - Inside buttons (24px)
  static const double buttonPaddingHorizontal = xxl;

  /// Button padding vertical - Inside buttons (16px)
  static const double buttonPaddingVertical = lg;

  /// Input padding - Inside text fields (16px)
  static const double inputPadding = lg;

  /// Input spacing - Between form fields (16px)
  static const double inputSpacing = lg;

  /// Icon spacing - Next to text (8px)
  static const double iconSpacing = sm;

  /// Chip padding - Inside chips (12px horizontal, 8px vertical)
  static const double chipPaddingHorizontal = md;
  static const double chipPaddingVertical = sm;

  /// Modal padding - Inside modals and dialogs (24px)
  static const double modalPadding = xxl;

  /// Bottom sheet padding - Inside bottom sheets (24px)
  static const double bottomSheetPadding = xxl;

  /// Divider spacing - Around dividers (16px)
  static const double dividerSpacing = lg;

  /// Grid spacing - Between grid items (12px)
  static const double gridSpacing = md;

  // ============= BORDER RADIUS =============

  /// No radius - 0px (Sharp corners)
  static const double radiusNone = 0.0;

  /// Extra small radius - 2px
  static const double radiusXs = 2.0;

  /// Small radius - 4px
  static const double radiusSm = 4.0;

  /// Medium radius - 8px (Most commonly used)
  static const double radiusMd = 8.0;

  /// Large radius - 12px
  static const double radiusLg = 12.0;

  /// Extra large radius - 16px
  static const double radiusXl = 16.0;

  /// Extra extra large radius - 24px
  static const double radiusXxl = 24.0;

  /// Full radius - 999px (Pill shape)
  static const double radiusFull = 999.0;

  /// Circle radius - 50% (For circular elements, use ClipOval instead)
  static const double radiusCircle = 9999.0;

  // ============= ELEVATION / SHADOW =============

  /// Elevation level 0 - No shadow
  static const double elevation0 = 0.0;

  /// Elevation level 1 - Subtle shadow (Cards, inputs)
  static const double elevation1 = 1.0;

  /// Elevation level 2 - Light shadow (Raised cards)
  static const double elevation2 = 2.0;

  /// Elevation level 3 - Medium shadow (Floating action button)
  static const double elevation3 = 3.0;

  /// Elevation level 4 - Strong shadow (App bar)
  static const double elevation4 = 4.0;

  /// Elevation level 6 - Heavy shadow (Modal dialogs)
  static const double elevation6 = 6.0;

  /// Elevation level 8 - Very heavy shadow (Navigation drawer)
  static const double elevation8 = 8.0;

  /// Elevation level 12 - Maximum shadow (Popups, dropdowns)
  static const double elevation12 = 12.0;

  // ============= ICON SIZES =============

  /// Extra small icon - 12px
  static const double iconXs = 12.0;

  /// Small icon - 16px
  static const double iconSm = 16.0;

  /// Medium icon - 20px
  static const double iconMd = 20.0;

  /// Large icon - 24px (Most commonly used)
  static const double iconLg = 24.0;

  /// Extra large icon - 32px
  static const double iconXl = 32.0;

  /// Extra extra large icon - 48px
  static const double iconXxl = 48.0;

  /// Huge icon - 64px
  static const double iconHuge = 64.0;

  // ============= BUTTON HEIGHTS =============

  /// Small button - 36px
  static const double buttonHeightSm = 36.0;

  /// Medium button - 44px
  static const double buttonHeightMd = 44.0;

  /// Large button - 50px (Most commonly used)
  static const double buttonHeightLg = 50.0;

  /// Extra large button - 56px
  static const double buttonHeightXl = 56.0;

  // ============= INPUT HEIGHTS =============

  /// Small input - 40px
  static const double inputHeightSm = 40.0;

  /// Medium input - 48px
  static const double inputHeightMd = 48.0;

  /// Large input - 56px
  static const double inputHeightLg = 56.0;

  // ============= AVATAR SIZES =============

  /// Extra small avatar - 24px
  static const double avatarXs = 24.0;

  /// Small avatar - 32px
  static const double avatarSm = 32.0;

  /// Medium avatar - 40px
  static const double avatarMd = 40.0;

  /// Large avatar - 48px
  static const double avatarLg = 48.0;

  /// Extra large avatar - 64px
  static const double avatarXl = 64.0;

  /// Extra extra large avatar - 96px
  static const double avatarXxl = 96.0;

  /// Huge avatar - 128px
  static const double avatarHuge = 128.0;

  // ============= APP BAR =============

  /// App bar height - 56px
  static const double appBarHeight = 56.0;

  /// App bar elevation
  static const double appBarElevation = elevation0;

  // ============= BOTTOM NAVIGATION =============

  /// Bottom navigation height - 64px
  static const double bottomNavHeight = 64.0;

  /// Bottom navigation elevation
  static const double bottomNavElevation = elevation4;

  // ============= TAB BAR =============

  /// Tab bar height - 48px
  static const double tabBarHeight = 48.0;

  /// Tab indicator height - 3px
  static const double tabIndicatorHeight = 3.0;

  // ============= DIVIDER =============

  /// Divider thickness - 1px
  static const double dividerThickness = 1.0;

  /// Thick divider - 2px
  static const double dividerThick = 2.0;

  // ============= WEB & RESPONSIVE BREAKPOINTS =============

  /// Mobile max width - 600px
  static const double breakpointMobile = 600.0;

  /// Tablet max width - 900px
  static const double breakpointTablet = 900.0;

  /// Desktop min width - 1200px
  static const double breakpointDesktop = 1200.0;

  /// Web content max width - 600px (for centered layouts)
  static const double webMaxWidth = 600.0;

  /// Web content padding - 24px
  static const double webContentPadding = xxl;

  // ============= LEGACY SUPPORT (Deprecated) =============

  @Deprecated('Use AppSpacing.lg instead')
  static const double defaultPadding = lg;

  @Deprecated('Use AppSpacing.radiusMd instead')
  static const double defaultRadius = radiusMd;

  @Deprecated('Use AppSpacing.webMaxWidth instead')
  static const double maxWebWidth = webMaxWidth;

  @Deprecated('Use AppSpacing.screenPaddingHorizontal instead')
  static const double screenPadding = screenPaddingHorizontal;

  @Deprecated('Use AppSpacing.sectionSpacing instead')
  static const double sectionPadding = sectionSpacing;
}
