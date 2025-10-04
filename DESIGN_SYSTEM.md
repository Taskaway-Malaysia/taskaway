# Taskaway Design System

> **Complete UI/UX standardization guide for consistent, beautiful interfaces**

## 📋 Table of Contents

1. [Overview](#overview)
2. [Colors](#colors)
3. [Typography](#typography)
4. [Spacing & Layout](#spacing--layout)
5. [Components](#components)
6. [Usage Examples](#usage-examples)
7. [Migration Guide](#migration-guide)

---

## Overview

The Taskaway Design System is a comprehensive, standardized UI framework built on Material Design 3 principles. It ensures complete consistency across all screens and components.

### Design Philosophy

- **Semantic Naming**: Clear, purpose-driven naming for all design tokens
- **Single Source of Truth**: All design values in centralized constants
- **Accessibility First**: WCAG AA compliant color contrast ratios
- **Developer Experience**: Easy-to-use, well-documented APIs

### Core Files

```
lib/core/theme/
├── app_colors.dart      # Complete color palette
├── app_typography.dart  # Text styles and fonts
├── app_spacing.dart     # Spacing, sizing, and layout
└── app_theme.dart       # Material theme configuration

lib/core/widgets/
├── app_button.dart      # Standardized buttons
├── app_text_field.dart  # Form inputs
└── app_card.dart        # Card containers
```

---

## Colors

### Brand Colors

#### Primary (Orange/Gold)
```dart
AppColors.primary           // #EB9F2F - Main brand color
AppColors.primaryDark       // #D18A1F - Hover/pressed states
AppColors.primaryLight      // #F9D281 - Backgrounds
AppColors.primaryExtraLight // #FEF4D5 - Subtle backgrounds
```

#### Accent (Purple)
```dart
AppColors.accent           // #7773D2 - Secondary actions
AppColors.accentDark       // #5F5BB8 - Dark variant
AppColors.accentLight      // #B3AFF1 - Light variant
AppColors.accentExtraLight // #E7E5FC - Subtle backgrounds
```

### Neutral Colors (Gray Scale)

```dart
// Use for text, borders, and backgrounds
AppColors.black    // #000000
AppColors.white    // #FFFFFF
AppColors.gray950  // #0A0A0A - Almost black
AppColors.gray900  // #1A1A1A - Very dark
AppColors.gray800  // #202020 - Primary text
AppColors.gray700  // #404040
AppColors.gray600  // #6B7280 - Secondary text
AppColors.gray500  // #788494
AppColors.gray400  // #9CA3AF - Tertiary text
AppColors.gray300  // #D1D5DB - Disabled text
AppColors.gray200  // #E5E7EB - Borders
AppColors.gray100  // #F3F4F6 - Input backgrounds
AppColors.gray50   // #F9FAFB - Subtle backgrounds
AppColors.gray25   // #FCFCFD - Almost white
```

### Semantic Colors

#### Text Colors
```dart
AppColors.textPrimary    // Gray 800 - Headings, main content
AppColors.textSecondary  // Gray 600 - Body text
AppColors.textTertiary   // Gray 400 - Hints, captions
AppColors.textDisabled   // Gray 300 - Disabled states
AppColors.textInverted   // White - On dark backgrounds
AppColors.textLink       // Primary - Clickable links
```

#### Background Colors
```dart
AppColors.backgroundPrimary   // White - Main screens
AppColors.backgroundSecondary // Gray 50 - Cards, surfaces
AppColors.backgroundTertiary  // Gray 100 - Input fields
AppColors.backgroundDisabled  // Gray 100 - Disabled elements
AppColors.backgroundHover     // Gray 50 - Hover states
AppColors.backgroundOverlay   // Black 50% - Modals
AppColors.backgroundToast     // Gray 900 - Notifications
```

#### Border Colors
```dart
AppColors.borderDefault  // Gray 200 - Standard borders
AppColors.borderLight    // Gray 100 - Subtle separators
AppColors.borderMedium   // Gray 300 - Emphasized borders
AppColors.borderDark     // Gray 400 - Strong borders
AppColors.borderFocus    // Primary - Input focus
AppColors.borderError    // Error - Error states
AppColors.borderSuccess  // Success - Success states
```

#### Status Colors
```dart
// Success (Green)
AppColors.success           // #10B981
AppColors.successDark       // #059669
AppColors.successLight      // #D1FAE5
AppColors.successExtraLight // #ECFDF5

// Error (Red)
AppColors.error           // #EF4444
AppColors.errorDark       // #DC2626
AppColors.errorLight      // #FEE2E2
AppColors.errorExtraLight // #FEF2F2

// Warning (Orange)
AppColors.warning           // #F59E0B
AppColors.warningDark       // #D97706
AppColors.warningLight      // #FED7AA
AppColors.warningExtraLight // #FEF3C7

// Info (Blue)
AppColors.info           // #3B82F6
AppColors.infoDark       // #2563EB
AppColors.infoLight      // #DBEAFE
AppColors.infoExtraLight // #EFF6FF
```

### Special Colors
```dart
AppColors.star          // #FCC133 - Star ratings
AppColors.statusOnline  // #10B981 - Online indicator
AppColors.statusOffline // #9CA3AF - Offline indicator
AppColors.statusAway    // #F59E0B - Away indicator
AppColors.statusBusy    // #EF4444 - Busy indicator
AppColors.shadow        // Black 10% - Elevations
```

---

## Typography

### Font Family
- **Primary**: Inter
- **Fallback**: System default

### Text Styles

#### Display (Hero Text)
```dart
AppTypography.displayLarge  // 48px, Bold - Hero sections
AppTypography.displayMedium // 36px, Bold - Large features
AppTypography.displaySmall  // 32px, SemiBold - Section heroes
```

#### Headline (Page Titles)
```dart
AppTypography.headlineLarge  // 28px, Bold - Main page titles
AppTypography.headlineMedium // 24px, SemiBold - Screen headers
AppTypography.headlineSmall  // 20px, SemiBold - Subpage titles
```

#### Title (Section Headers)
```dart
AppTypography.titleLarge  // 18px, SemiBold - Section headings
AppTypography.titleMedium // 16px, SemiBold - Card titles
AppTypography.titleSmall  // 14px, SemiBold - List headers
```

#### Body (Main Content)
```dart
AppTypography.bodyLarge  // 16px, Regular - Main content
AppTypography.bodyMedium // 14px, Regular - Standard text
AppTypography.bodySmall  // 12px, Regular - Small text
```

#### Label (Buttons & UI)
```dart
AppTypography.labelLarge  // 16px, Medium - Large buttons
AppTypography.labelMedium // 14px, Medium - Standard buttons
AppTypography.labelSmall  // 12px, Medium - Small buttons
```

#### Caption (Helper Text)
```dart
AppTypography.captionLarge  // 12px, Regular - Helper text
AppTypography.captionMedium // 11px, Regular - Timestamps
AppTypography.captionSmall  // 10px, Regular - Fine print
```

#### Specialized
```dart
AppTypography.link         // 14px, Medium - Links
AppTypography.overline     // 12px, SemiBold, Uppercase - Labels
AppTypography.code         // 12px, Monospace - Code snippets
AppTypography.buttonPrimary   // 16px, SemiBold - Primary buttons
AppTypography.buttonSecondary // 16px, SemiBold - Secondary buttons
AppTypography.buttonText      // 14px, Medium - Text buttons
```

#### Input Styles
```dart
AppTypography.input       // 16px, Regular - Input text
AppTypography.inputLabel  // 14px, Medium - Field labels
AppTypography.inputHint   // 16px, Regular - Placeholders
AppTypography.inputError  // 12px, Regular - Error messages
AppTypography.inputHelper // 12px, Regular - Helper text
```

### Font Weights
```dart
AppTypography.light      // 300
AppTypography.regular    // 400
AppTypography.medium     // 500
AppTypography.semiBold   // 600
AppTypography.bold       // 700
AppTypography.extraBold  // 800
```

---

## Spacing & Layout

### Base Spacing Units (4px grid)

```dart
AppSpacing.xxs   // 2px
AppSpacing.xs    // 4px
AppSpacing.sm    // 8px
AppSpacing.md    // 12px
AppSpacing.lg    // 16px  ← Most common
AppSpacing.xl    // 20px
AppSpacing.xxl   // 24px
AppSpacing.xxxl  // 32px
AppSpacing.huge  // 40px
AppSpacing.xhuge // 48px
AppSpacing.massive // 64px
```

### Semantic Spacing

```dart
// Screen & Layout
AppSpacing.screenPaddingHorizontal // 16px
AppSpacing.screenPaddingVertical   // 20px
AppSpacing.sectionSpacing          // 32px

// Components
AppSpacing.cardPadding        // 16px
AppSpacing.cardMargin         // 12px
AppSpacing.listItemPadding    // 16px
AppSpacing.listItemSpacing    // 8px
AppSpacing.buttonPaddingHorizontal // 24px
AppSpacing.buttonPaddingVertical   // 16px
AppSpacing.inputPadding       // 16px
AppSpacing.inputSpacing       // 16px
AppSpacing.iconSpacing        // 8px
AppSpacing.modalPadding       // 24px
AppSpacing.bottomSheetPadding // 24px
AppSpacing.dividerSpacing     // 16px
AppSpacing.gridSpacing        // 12px
```

### Border Radius

```dart
AppSpacing.radiusNone  // 0px - Sharp corners
AppSpacing.radiusXs    // 2px
AppSpacing.radiusSm    // 4px
AppSpacing.radiusMd    // 8px  ← Most common
AppSpacing.radiusLg    // 12px
AppSpacing.radiusXl    // 16px
AppSpacing.radiusXxl   // 24px
AppSpacing.radiusFull  // 999px - Pill shape
```

### Elevation (Shadows)

```dart
AppSpacing.elevation0  // 0 - No shadow
AppSpacing.elevation1  // 1 - Subtle (cards)
AppSpacing.elevation2  // 2 - Light (raised cards)
AppSpacing.elevation3  // 3 - Medium (FAB)
AppSpacing.elevation4  // 4 - Strong (app bar)
AppSpacing.elevation6  // 6 - Heavy (modals)
AppSpacing.elevation8  // 8 - Very heavy (drawer)
AppSpacing.elevation12 // 12 - Maximum (dropdowns)
```

### Component Sizes

#### Icons
```dart
AppSpacing.iconXs   // 12px
AppSpacing.iconSm   // 16px
AppSpacing.iconMd   // 20px
AppSpacing.iconLg   // 24px ← Most common
AppSpacing.iconXl   // 32px
AppSpacing.iconXxl  // 48px
AppSpacing.iconHuge // 64px
```

#### Buttons
```dart
AppSpacing.buttonHeightSm // 36px
AppSpacing.buttonHeightMd // 44px
AppSpacing.buttonHeightLg // 50px ← Most common
AppSpacing.buttonHeightXl // 56px
```

#### Inputs
```dart
AppSpacing.inputHeightSm // 40px
AppSpacing.inputHeightMd // 48px
AppSpacing.inputHeightLg // 56px
```

#### Avatars
```dart
AppSpacing.avatarXs   // 24px
AppSpacing.avatarSm   // 32px
AppSpacing.avatarMd   // 40px
AppSpacing.avatarLg   // 48px
AppSpacing.avatarXl   // 64px
AppSpacing.avatarXxl  // 96px
AppSpacing.avatarHuge // 128px
```

### Responsive Breakpoints

```dart
AppSpacing.breakpointMobile  // 600px
AppSpacing.breakpointTablet  // 900px
AppSpacing.breakpointDesktop // 1200px
AppSpacing.webMaxWidth       // 600px
```

---

## Components

### AppButton

Standardized button with multiple variants and sizes.

#### Variants

```dart
// Primary Button (Orange background)
AppButton.primary(
  text: 'Continue',
  onPressed: () {},
)

// Secondary Button (Outlined)
AppButton.secondary(
  text: 'Cancel',
  onPressed: () {},
)

// Text Button (Minimal)
AppButton.text(
  text: 'Learn More',
  onPressed: () {},
)

// Danger Button (Destructive)
AppButton.danger(
  text: 'Delete',
  onPressed: () {},
)
```

#### Sizes

```dart
AppButton(
  text: 'Button',
  onPressed: () {},
  size: AppButtonSize.small,    // 36px height
  size: AppButtonSize.medium,   // 44px height
  size: AppButtonSize.large,    // 50px height (default)
  size: AppButtonSize.extraLarge, // 56px height
)
```

#### With Icons

```dart
AppButton.primary(
  text: 'Add Task',
  leftIcon: Icons.add,
  onPressed: () {},
)

AppButton.secondary(
  text: 'Next',
  rightIcon: Icons.arrow_forward,
  onPressed: () {},
)
```

#### Loading State

```dart
AppButton.primary(
  text: 'Submit',
  isLoading: true,
  onPressed: () {},
)
```

---

### AppTextField

Standardized text input with multiple variants.

#### Basic Input

```dart
AppTextField(
  label: 'Full Name',
  hintText: 'Enter your name',
  controller: nameController,
  onChanged: (value) {},
)
```

#### Specialized Inputs

```dart
// Email
AppTextField.email(
  controller: emailController,
)

// Password
AppTextField.password(
  controller: passwordController,
  suffixIcon: IconButton(
    icon: Icon(Icons.visibility),
    onPressed: () {},
  ),
)

// Phone
AppTextField.phone(
  controller: phoneController,
)

// Search
AppTextField.search(
  hintText: 'Search tasks...',
  onChanged: (query) {},
  onClear: () {},
)

// Multiline
AppTextField.multiline(
  label: 'Description',
  maxLines: 5,
  controller: descriptionController,
)
```

#### With Validation

```dart
AppTextField(
  label: 'Email',
  controller: emailController,
  validator: (value) {
    if (value?.isEmpty ?? true) {
      return 'Email is required';
    }
    return null;
  },
)
```

---

### AppCard

Standardized card container for content.

#### Basic Card

```dart
AppCard(
  child: Text('Card Content'),
)

// With padding
AppCard.padded(
  child: Column(
    children: [
      Text('Title'),
      Text('Content'),
    ],
  ),
)
```

#### Card Variants

```dart
// Outlined
AppCard.outlined(
  child: Text('Outlined Card'),
)

// Elevated
AppCard.elevated(
  child: Text('Elevated Card'),
)

// Tappable
AppCard.padded(
  onTap: () {
    // Handle tap
  },
  child: Text('Tap me'),
)
```

#### Info Cards

```dart
// Info
AppInfoCard.info(
  message: 'This is an informational message',
)

// Success
AppInfoCard.success(
  message: 'Task completed successfully!',
  onClose: () {},
)

// Warning
AppInfoCard.warning(
  message: 'Please verify your email',
)

// Error
AppInfoCard.error(
  message: 'Something went wrong',
)
```

---

## Usage Examples

### Complete Form Example

```dart
class LoginScreen extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.screenPaddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: AppSpacing.xxl),

            Text(
              'Welcome Back',
              style: AppTypography.displaySmall,
            ),

            SizedBox(height: AppSpacing.lg),

            Text(
              'Sign in to continue',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            SizedBox(height: AppSpacing.xxxl),

            AppTextField.email(
              controller: emailController,
            ),

            SizedBox(height: AppSpacing.lg),

            AppTextField.password(
              controller: passwordController,
            ),

            SizedBox(height: AppSpacing.xxl),

            AppButton.primary(
              text: 'Sign In',
              onPressed: () {},
            ),

            SizedBox(height: AppSpacing.md),

            AppButton.text(
              text: 'Forgot Password?',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
```

### Card List Example

```dart
ListView.builder(
  padding: EdgeInsets.all(AppSpacing.lg),
  itemCount: tasks.length,
  itemBuilder: (context, index) {
    final task = tasks[index];

    return AppCard.padded(
      onTap: () {
        // Navigate to task details
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: AppTypography.titleMedium,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            task.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: AppSpacing.iconSm,
                color: AppColors.textTertiary,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                task.location,
                style: AppTypography.captionMedium,
              ),
            ],
          ),
        ],
      ),
    );
  },
)
```

### Status Message Example

```dart
Column(
  children: [
    if (showSuccess)
      AppInfoCard.success(
        message: 'Your task has been posted!',
        onClose: () {
          setState(() => showSuccess = false);
        },
      ),

    if (error != null)
      AppInfoCard.error(
        message: error,
      ),

    // Rest of content
  ],
)
```

---

## Migration Guide

### Step 1: Update Imports

Replace old imports with new design system:

```dart
// ❌ Old
import '../constants/style_constants.dart';

// ✅ New
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
```

### Step 2: Replace Colors

```dart
// ❌ Old
Color(0xFFFFDB5B)
StyleConstants.posterColorPrimary
StyleConstants.taskerColorPrimary
Colors.grey[600]

// ✅ New
AppColors.primary
AppColors.accent
AppColors.textSecondary
```

### Step 3: Replace Text Styles

```dart
// ❌ Old
TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: Colors.black,
)

// ✅ New
AppTypography.headlineSmall
```

### Step 4: Replace Spacing

```dart
// ❌ Old
EdgeInsets.all(16)
BorderRadius.circular(8)
const SizedBox(height: 20)

// ✅ New
EdgeInsets.all(AppSpacing.lg)
BorderRadius.circular(AppSpacing.radiusMd)
SizedBox(height: AppSpacing.xl)
```

### Step 5: Use Standard Components

```dart
// ❌ Old
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFEB9F2F),
    // ... many style properties
  ),
  child: Text('Submit'),
  onPressed: () {},
)

// ✅ New
AppButton.primary(
  text: 'Submit',
  onPressed: () {},
)
```

### Deprecated Colors (Legacy Support)

These old colors still work but show deprecation warnings:

```dart
@Deprecated('Use AppColors.primary instead')
AppColors.primaryYellow

@Deprecated('Use AppColors.gray800 instead')
AppColors.primaryBlack

@Deprecated('Use AppColors.success instead')
AppColors.successGreen

// ... and more
```

---

## Best Practices

### ✅ DO

- Use semantic color names (`AppColors.textPrimary` not `AppColors.gray800`)
- Use spacing constants (`AppSpacing.lg` not `16.0`)
- Use standard components (`AppButton.primary` not custom `ElevatedButton`)
- Use typography styles (`AppTypography.bodyMedium` not manual `TextStyle`)
- Keep designs consistent across all screens

### ❌ DON'T

- Hardcode color values (`Color(0xFF...)`)
- Hardcode spacing values (`EdgeInsets.all(16)`)
- Create custom button styles
- Mix different design patterns
- Use deprecated color names

---

## Support

For questions or issues with the design system:

1. Check this documentation first
2. Review the source files in `/lib/core/theme/`
3. Look at component examples in `/lib/core/widgets/`
4. Check existing screens for implementation patterns

---

**Last Updated**: 2025-10-05
**Version**: 1.0.0
**Status**: ✅ Complete & Production Ready
