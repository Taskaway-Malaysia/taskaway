import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// AppAvatar - Standardized avatar component
///
/// A reusable avatar widget that displays user profile images with proper fallbacks.
///
/// Features:
/// - Multiple sizes (small, medium, large, xlarge)
/// - Automatic initials generation
/// - Network image support with caching
/// - Local asset support
/// - Loading states
/// - Error handling
/// - Customizable colors
/// - Border support
/// - Badge overlay support
///
/// Usage:
/// ```dart
/// // Network image
/// AppAvatar.network(
///   imageUrl: 'https://example.com/avatar.jpg',
///   name: 'John Doe',
///   size: AppAvatarSize.medium,
/// )
///
/// // Initials only
/// AppAvatar.initials(
///   name: 'Jane Smith',
///   size: AppAvatarSize.large,
/// )
///
/// // With badge
/// AppAvatar.network(
///   imageUrl: url,
///   name: 'User',
///   showBadge: true,
///   badgeColor: AppColors.statusOnline,
/// )
/// ```
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final AppAvatarSize size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showBorder;
  final Color? borderColor;
  final double? borderWidth;
  final bool showBadge;
  final Color? badgeColor;
  final Widget? badge;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppAvatarSize.medium,
    this.backgroundColor,
    this.textColor,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth,
    this.showBadge = false,
    this.badgeColor,
    this.badge,
    this.onTap,
  });

  /// Create avatar with network image
  const AppAvatar.network({
    super.key,
    required this.imageUrl,
    required this.name,
    this.size = AppAvatarSize.medium,
    this.backgroundColor,
    this.textColor,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth,
    this.showBadge = false,
    this.badgeColor,
    this.badge,
    this.onTap,
  });

  /// Create avatar with initials only
  const AppAvatar.initials({
    super.key,
    required this.name,
    this.size = AppAvatarSize.medium,
    this.backgroundColor,
    this.textColor,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth,
    this.showBadge = false,
    this.badgeColor,
    this.badge,
    this.onTap,
  }) : imageUrl = null;

  @override
  Widget build(BuildContext context) {
    final avatarSize = _getSize();
    final widget = Stack(
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor ?? _getDefaultBackgroundColor(),
            border: showBorder
                ? Border.all(
                    color: borderColor ?? AppColors.white,
                    width: borderWidth ?? 2.0,
                  )
                : null,
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildInitials();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildInitials();
                    },
                  )
                : _buildInitials(),
          ),
        ),
        if (showBadge || badge != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: badge ??
                Container(
                  width: avatarSize * 0.25,
                  height: avatarSize * 0.25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeColor ?? AppColors.statusOnline,
                    border: Border.all(
                      color: AppColors.white,
                      width: 2.0,
                    ),
                  ),
                ),
          ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(avatarSize / 2),
        child: widget,
      );
    }

    return widget;
  }

  Widget _buildInitials() {
    final initials = _getInitials();
    final fontSize = _getFontSize();

    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.textInverted,
          fontFamily: AppTypography.fontFamily,
        ),
      ),
    );
  }

  String _getInitials() {
    if (name == null || name!.isEmpty) return '?';

    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  double _getSize() {
    switch (size) {
      case AppAvatarSize.small:
        return 32.0;
      case AppAvatarSize.medium:
        return 40.0;
      case AppAvatarSize.large:
        return 56.0;
      case AppAvatarSize.xlarge:
        return 80.0;
      case AppAvatarSize.xxlarge:
        return 120.0;
    }
  }

  double _getFontSize() {
    switch (size) {
      case AppAvatarSize.small:
        return 12.0;
      case AppAvatarSize.medium:
        return 14.0;
      case AppAvatarSize.large:
        return 20.0;
      case AppAvatarSize.xlarge:
        return 28.0;
      case AppAvatarSize.xxlarge:
        return 40.0;
    }
  }

  Color _getDefaultBackgroundColor() {
    // Generate consistent color based on name hash
    if (name == null || name!.isEmpty) {
      return AppColors.gray400;
    }

    final hash = name!.hashCode;
    final colors = [
      AppColors.accent,
      AppColors.posterPrimary,
      AppColors.taskerPrimary,
      AppColors.info,
      AppColors.success,
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFE91E63), // Pink
      const Color(0xFF00BCD4), // Cyan
    ];

    return colors[hash.abs() % colors.length];
  }
}

/// Avatar size options
enum AppAvatarSize {
  /// 32x32 - For lists and compact views
  small,

  /// 40x40 - Default size for most use cases
  medium,

  /// 56x56 - For prominent display
  large,

  /// 80x80 - For profile headers
  xlarge,

  /// 120x120 - For full profile pages
  xxlarge,
}
