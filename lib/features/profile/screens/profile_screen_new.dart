import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

class ProfileScreenNew extends ConsumerWidget {
  const ProfileScreenNew({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderDefault,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(width: AppSpacing.lg),
                  InkWell(
                    onTap: () {
                      // Check if we can pop, otherwise navigate to home
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    child: Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Profile',
                        style: AppTypography.headlineMedium,
                      ),
                    ),
                  ),
                  SizedBox(width: 36),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: profileAsync.when(
                  data: (profile) => Column(
                    children: [
                      // User Info Card
                      _UserInfoCard(
                        name: profile?.fullName ?? 'Guest User',
                        rating: 5.0,
                        avatarUrl: profile?.avatarUrl,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      // Location Card
                      _InfoCard(
                        children: [
                          _InfoRow(
                            label: 'From',
                            value: profile?.postcode != null
                                ? 'Postcode ${profile!.postcode}'
                                : 'Add your location',
                            isPlaceholder: profile?.postcode == null,
                          ),
                          SizedBox(height: AppSpacing.lg),
                          _InfoRow(
                            label: 'Member since',
                            value: profile?.createdAt != null
                                ? DateFormat('MMMM yyyy').format(profile!.createdAt!)
                                : 'November 2023',
                            isPlaceholder: false,
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.lg),
                      // About Card
                      _EditableInfoCard(
                        title: 'About',
                        content: profile?.bio ?? 'Add information about yourself to let others know more about you.',
                        isPlaceholder: profile?.bio == null,
                        onEdit: () {
                          // TODO: Navigate to edit about
                        },
                      ),
                      SizedBox(height: AppSpacing.lg),
                      // Skills Card
                      _EditableInfoCard(
                        title: 'Skills',
                        content: 'Please add your skills',
                        isPlaceholder: true,
                        onEdit: () {
                          // TODO: Navigate to edit skills
                        },
                      ),
                      SizedBox(height: AppSpacing.lg),
                      // My Works Card
                      _MyWorksCard(),
                      SizedBox(height: AppSpacing.xl),
                      // Logout Button
                      Center(
                        child: TextButton(
                          onPressed: () async {
                            // Show confirmation dialog
                            final shouldLogout = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                ),
                                title: Text(
                                  'Logout',
                                  style: AppTypography.titleLarge.copyWith(
                                    fontWeight: AppTypography.bold,
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to logout?',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(false),
                                    child: Text(
                                      'Cancel',
                                      style: AppTypography.labelLarge.copyWith(
                                        fontWeight: AppTypography.semiBold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                      foregroundColor: AppColors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                      ),
                                    ),
                                    child: Text(
                                      'Logout',
                                      style: AppTypography.labelLarge.copyWith(
                                        fontWeight: AppTypography.semiBold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (shouldLogout == true) {
                              await ref.read(authControllerProvider.notifier).signOut();
                              if (context.mounted) {
                                context.go('/auth/login');
                              }
                            }
                          },
                          child: Text(
                            'Logout',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: AppTypography.semiBold,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text(
                      'Error loading profile',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  final String name;
  final double rating;
  final String? avatarUrl;

  const _UserInfoCard({
    required this.name,
    required this.rating,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.borderDefault,
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null
                    ? Center(
                        child: Text(
                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                          style: AppTypography.headlineMedium.copyWith(
                            fontWeight: AppTypography.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : null,
              ),
              SizedBox(width: AppSpacing.md),
              // Name and Rating
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: AppTypography.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  // Star rating
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        size: 20,
                        color: AppColors.primary,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
          // Edit button
          InkWell(
            onTap: () {
              // TODO: Navigate to edit profile
            },
            child: Container(
              padding: EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primaryExtraLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                Icons.edit,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPlaceholder;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: AppTypography.semiBold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: isPlaceholder ? AppColors.textTertiary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _EditableInfoCard extends StatelessWidget {
  final String title;
  final String content;
  final bool isPlaceholder;
  final VoidCallback onEdit;

  const _EditableInfoCard({
    required this.title,
    required this.content,
    required this.isPlaceholder,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: AppTypography.semiBold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  content,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isPlaceholder ? AppColors.textTertiary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onEdit,
            child: Container(
              padding: EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primaryExtraLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                Icons.edit,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My works',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: AppTypography.semiBold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Please add your works',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  // TODO: Navigate to edit works
                },
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primaryExtraLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          // Work thumbnails
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? AppSpacing.sm : 0),
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.borderDefault),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        size: 24,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}