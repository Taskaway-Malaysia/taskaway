# Taskaway UI/UX Style Guide & Consistency Report

## 🎨 Current State Analysis

### Major Inconsistencies Found

#### 1. **Color Usage**
**Problem**: Multiple color values used for similar purposes

**Text Colors:**
- Black text: `Colors.black`, `Color(0xFF000000)`, `Color(0xFF202020)`, `Color(0xFF1A1A1A)`
- Gray text: `Color(0xFF6B7280)`, `Color(0xFF788494)`, `Color(0xFF9CA3AF)`, `Color(0xFF575656)`, `Colors.grey[600]`
- Border colors: `Color(0xFFE5E7EB)`, `Color(0xFFEDEDED)`, `Colors.grey[300]`

**Primary Colors:**
- Yellow: `Color(0xFFFFDB5B)`, `Color(0xFFFFC333)`, `Color(0xFFFCBE15)`
- Success: `Colors.green`, `Color(0xFF4CAF50)`
- Error: `Colors.red`, `Colors.red[700]`

#### 2. **Typography**
**Problem**: Inconsistent font families and sizes

**Font Families:**
- `'Instrument Sans'` (most screens)
- `'Roboto'` (some components)
- System default (older screens)

**Font Sizes Range:**
- Headers: 14px to 24px (inconsistent)
- Body text: 10px to 18px (too wide range)
- Buttons: 12px to 16px

#### 3. **Button Styles**
**Problem**: No consistent button implementation

**Variations Found:**
- Border radius: `BorderRadius.circular(2)`, `circular(4)`, `circular(8)`, `circular(12)`
- Heights: 48px, 50px, 56px, unspecified
- Padding: Various inconsistent values

#### 4. **Input Fields**
**Problem**: Different styles across screens

**Variations:**
- Background colors: `Colors.white`, `Color(0xFFF3F4F6)`, `Colors.grey[50]`
- Border radius: 4px, 6px, 8px, 12px
- Border colors: Multiple gray values

#### 5. **Spacing**
**Problem**: No consistent spacing system

**Common Values:**
- Padding: 8, 12, 16, 20, 24 (no clear system)
- Screen padding: Sometimes 16px, sometimes 20px, sometimes 24px

---

## ✅ Recommended Style System

### Color Palette

```dart
// Primary Colors
const Color primaryYellow = Color(0xFFFFDB5B);
const Color primaryYellowDark = Color(0xFFFFC333);
const Color primaryBlack = Color(0xFF202020);

// Text Colors
const Color textPrimary = Color(0xFF202020);     // Main text
const Color textSecondary = Color(0xFF6B7280);   // Secondary text
const Color textTertiary = Color(0xFF9CA3AF);    // Hints, placeholders
const Color textWhite = Colors.white;

// Background Colors
const Color backgroundWhite = Colors.white;
const Color backgroundGray = Color(0xFFF3F4F6);  // Input fields, cards
const Color backgroundLight = Color(0xFFF9FAFB); // Subtle backgrounds

// Border Colors
const Color borderDefault = Color(0xFFE5E7EB);
const Color borderLight = Color(0xFFF3F4F6);

// Status Colors
const Color successGreen = Color(0xFF10B981);
const Color errorRed = Color(0xFFEF4444);
const Color warningOrange = Color(0xFFF59E0B);
const Color infoBlue = Color(0xFF3B82F6);
```

### Typography System

```dart
// Font Family
const String fontFamily = 'Instrument Sans';

// Font Sizes
const double fontSize10 = 10.0;  // Tiny labels
const double fontSize12 = 12.0;  // Small text, captions
const double fontSize14 = 14.0;  // Body text, buttons
const double fontSize16 = 16.0;  // Subheadings
const double fontSize18 = 18.0;  // Section headers
const double fontSize20 = 20.0;  // Page titles
const double fontSize24 = 24.0;  // Large displays

// Font Weights
const FontWeight fontWeightRegular = FontWeight.w400;
const FontWeight fontWeightMedium = FontWeight.w500;
const FontWeight fontWeightSemiBold = FontWeight.w600;
const FontWeight fontWeightBold = FontWeight.w700;

// Text Styles
const TextStyle headingLarge = TextStyle(
  fontFamily: fontFamily,
  fontSize: fontSize20,
  fontWeight: fontWeightSemiBold,
  color: textPrimary,
);

const TextStyle headingMedium = TextStyle(
  fontFamily: fontFamily,
  fontSize: fontSize18,
  fontWeight: fontWeightSemiBold,
  color: textPrimary,
);

const TextStyle headingSmall = TextStyle(
  fontFamily: fontFamily,
  fontSize: fontSize16,
  fontWeight: fontWeightSemiBold,
  color: textPrimary,
);

const TextStyle bodyLarge = TextStyle(
  fontFamily: fontFamily,
  fontSize: fontSize16,
  fontWeight: fontWeightRegular,
  color: textPrimary,
  height: 1.5,
);

const TextStyle bodyMedium = TextStyle(
  fontFamily: fontFamily,
  fontSize: fontSize14,
  fontWeight: fontWeightRegular,
  color: textPrimary,
  height: 1.5,
);

const TextStyle bodySmall = TextStyle(
  fontFamily: fontFamily,
  fontSize: fontSize12,
  fontWeight: fontWeightRegular,
  color: textSecondary,
);

const TextStyle labelLarge = TextStyle(
  fontFamily: fontFamily,
  fontSize: fontSize14,
  fontWeight: fontWeightMedium,
  color: textPrimary,
);

const TextStyle labelSmall = TextStyle(
  fontFamily: fontFamily,
  fontSize: fontSize12,
  fontWeight: fontWeightMedium,
  color: textSecondary,
);
```

### Component Styles

#### Buttons

```dart
// Primary Button (Yellow)
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: primaryYellow,
    foregroundColor: primaryBlack,
    minimumSize: const Size(double.infinity, 50),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: primaryYellowDark),
    ),
    elevation: 0,
  ),
  child: Text(
    'Button Text',
    style: labelLarge.copyWith(fontWeight: fontWeightSemiBold),
  ),
)

// Secondary Button (Outlined)
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: textPrimary,
    minimumSize: const Size(double.infinity, 50),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    side: const BorderSide(color: borderDefault),
  ),
  child: Text('Button Text', style: labelLarge),
)

// Text Button
TextButton(
  style: TextButton.styleFrom(
    foregroundColor: primaryYellowDark,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  child: Text('Button Text', style: labelLarge),
)
```

#### Input Fields

```dart
// Standard Input Field
TextFormField(
  style: bodyMedium,
  decoration: InputDecoration(
    hintText: 'Placeholder text',
    hintStyle: bodyMedium.copyWith(color: textTertiary),
    filled: true,
    fillColor: backgroundGray,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: borderDefault),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: borderDefault),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: borderDefault, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: errorRed),
    ),
  ),
)
```

#### Cards & Containers

```dart
// Standard Card
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: backgroundWhite,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderLight),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: // content
)
```

### Spacing System

```dart
// Use multiples of 4
const double space4 = 4.0;
const double space8 = 8.0;
const double space12 = 12.0;
const double space16 = 16.0;
const double space20 = 20.0;
const double space24 = 24.0;
const double space32 = 32.0;
const double space40 = 40.0;
const double space48 = 48.0;

// Standard screen padding
const EdgeInsets screenPadding = EdgeInsets.all(16);
const EdgeInsets sectionPadding = EdgeInsets.symmetric(vertical: 24);
```

---

## 🔧 Implementation Recommendations

### Priority 1: Create Core Style Files
1. Create `lib/core/theme/app_colors.dart` with all color constants
2. Create `lib/core/theme/app_typography.dart` with text styles
3. Create `lib/core/theme/app_spacing.dart` with spacing constants
4. Create `lib/core/theme/app_components.dart` with reusable styled widgets

### Priority 2: Update Critical Screens
1. **Home Screen** - Main entry point
2. **Task Details** - High traffic screen
3. **Create Task** - Important flow
4. **Message Screen** - Communication hub
5. **Profile Screen** - User settings

### Priority 3: Component Library
1. Create `AppButton` widget with variants (primary, secondary, text)
2. Create `AppTextField` widget with consistent styling
3. Create `AppCard` widget for containers
4. Create `AppHeader` widget for consistent headers

### Files Requiring Immediate Attention

1. **Inconsistent Font Families:**
   - `/lib/features/home/screens/home_screen.dart` - Uses Roboto
   - `/lib/features/tasks/screens/task_details_screen_new.dart` - Mixed fonts
   
2. **Inconsistent Colors:**
   - `/lib/features/messages/screens/message_screen.dart` - Multiple gray values
   - `/lib/features/home/screens/map_home_screen.dart` - Different yellows
   
3. **Inconsistent Buttons:**
   - `/lib/features/tasks/screens/apply_task_screen.dart` - Different button height
   - `/lib/features/auth/screens/auth_screen.dart` - Different border radius

4. **Inconsistent Inputs:**
   - Multiple background colors across different screens
   - Varying border radius values

---

## 📊 Metrics

- **Color Variations**: 15+ different gray values → Reduce to 3
- **Font Size Variations**: 12 different sizes → Reduce to 7
- **Button Styles**: 8+ variations → Reduce to 3
- **Border Radius Values**: 6 different values → Standardize to 2 (8px default, 4px small)

---

## ✅ Next Steps

1. **Review and approve** this style guide
2. **Create theme files** with constants
3. **Update screens progressively** starting with high-traffic areas
4. **Create reusable components** to enforce consistency
5. **Document** the style system for future development

This standardization will:
- Improve user experience through consistency
- Reduce development time
- Make maintenance easier
- Create a more professional appearance
- Reduce app size by eliminating redundant styles