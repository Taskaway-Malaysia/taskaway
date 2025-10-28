import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/api_constants.dart';

class ProfileScreenNew extends ConsumerStatefulWidget {
  const ProfileScreenNew({super.key});

  @override
  ConsumerState<ProfileScreenNew> createState() => _ProfileScreenNewState();
}

class _ProfileScreenNewState extends ConsumerState<ProfileScreenNew> {
  final List<String> _workImages = [];
  final ImagePicker _picker = ImagePicker();
  final SupabaseService _supabaseService = SupabaseService();
  bool _isUploading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    // TODO: Load work images from profile data
  }

  Future<void> _editBio(String? currentBio) async {
    final controller = TextEditingController(text: currentBio);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
        ),
        title: Text(
          'About me',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Write a fun and punchy intro...',
            border: OutlineInputBorder(
              borderRadius: AppRadius.md,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: AppTypography.semiBold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.md,
              ),
            ),
            child: Text(
              'Save',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
      ),
    );

    // Dispose controller after dialog has fully closed
    // Use addPostFrameCallback to ensure disposal happens after widget rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (result != null && mounted) {
      // TODO: Save bio to database
      // Example: await ref.read(profileControllerProvider.notifier).updateBio(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bio updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _editSkills(List<String>? currentSkills) async {
    final controller = TextEditingController(
      text: currentSkills?.join(', ') ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
        ),
        title: Text(
          'Skills',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          maxLength: 200,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Add your skills separated by commas...',
            border: OutlineInputBorder(
              borderRadius: AppRadius.md,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: AppTypography.semiBold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.md,
              ),
            ),
            child: Text(
              'Save',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
      ),
    );

    // Dispose controller after dialog has fully closed
    // Use addPostFrameCallback to ensure disposal happens after widget rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (result != null && mounted) {
      // TODO: Save skills to database
      // Parse skills from comma-separated string
      // final skillsList = result.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      // await ref.read(profileControllerProvider.notifier).updateSkills(skillsList);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Skills updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_workImages.length >= 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum 3 images allowed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;

      setState(() {
        _isUploading = true;
      });

      final profile = await ref.read(currentProfileProvider.future);

      if (!mounted) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      if (profile == null) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile not found'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Upload to Supabase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}.jpg';
      final filePath = 'profiles/${profile.id}/works/$fileName';

      final imageUrl = await _supabaseService.uploadFile(
        filePath: filePath,
        file: image,
        bucket: ApiConstants.taskImagesBucket,
      );

      if (!mounted) return;

      if (imageUrl != null) {
        setState(() {
          _workImages.add(imageUrl);
          _isUploading = false;
        });

        // TODO: Save work images to profile database
        // await ref.read(profileControllerProvider.notifier).updateWorkImages(_workImages);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image uploaded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _removeWorkImage(int index) async {
    if (index >= _workImages.length) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
        ),
        title: Text(
          'Remove Image',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this image?',
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
                borderRadius: AppRadius.md,
              ),
            ),
            child: Text(
              'Remove',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final imageUrl = _workImages[index];

        // Delete from storage
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 3) {
          final filePath = pathSegments.sublist(2).join('/');
          await _supabaseService.deleteFile(
            bucket: ApiConstants.taskImagesBucket,
            filePath: filePath,
          );
        }

        if (mounted) {
          setState(() {
            _workImages.removeAt(index);
          });

          // TODO: Update work images in profile database
          // await ref.read(profileControllerProvider.notifier).updateWorkImages(_workImages);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image removed successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing image: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderDefault,
                    width: 1,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      'Profile',
                      style: AppTypography.headlineMedium,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditMode = !_isEditMode;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _isEditMode ? 'Done' : 'Edit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
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
                      SizedBox(height: AppSpacing.xl),
                      // Bio Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About me',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_isEditMode) ...[
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              'Write a fun and punchy intro.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          SizedBox(height: AppSpacing.lg),
                          if (_isEditMode)
                            InkWell(
                              onTap: () => _editBio(profile?.bio),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundPrimary,
                                  borderRadius: AppRadius.lg,
                                  border: Border.all(
                                    color: AppColors.borderDefault,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        profile?.bio ?? 'A little bit about you...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: profile?.bio == null
                                              ? AppColors.textTertiary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: AppRadius.lg,
                              ),
                              child: Text(
                                profile?.bio ?? 'No bio added yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: profile?.bio == null
                                      ? AppColors.textTertiary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Divider(
                        color: AppColors.borderLight,
                        thickness: 1,
                        height: 1,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      // Skills Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Skills',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_isEditMode) ...[
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              'Add your top skills and expertise.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          SizedBox(height: AppSpacing.lg),
                          if (_isEditMode)
                            InkWell(
                              onTap: () => _editSkills(profile?.skills),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundPrimary,
                                  borderRadius: AppRadius.lg,
                                  border: Border.all(
                                    color: AppColors.borderDefault,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        profile?.skills?.isNotEmpty == true
                                            ? profile!.skills!.join(', ')
                                            : 'Add your skills...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: profile?.skills?.isNotEmpty == true
                                              ? AppColors.textPrimary
                                              : AppColors.textTertiary,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: AppRadius.lg,
                              ),
                              child: Text(
                                profile?.skills?.isNotEmpty == true
                                    ? profile!.skills!.join(', ')
                                    : 'No skills added yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: profile?.skills?.isNotEmpty == true
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Divider(
                        color: AppColors.borderLight,
                        thickness: 1,
                        height: 1,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      // My Works Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My works',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_isEditMode) ...[
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'Please add your works',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                          SizedBox(height: AppSpacing.lg),
                          // Work thumbnails
                          if (_workImages.isEmpty && !_isEditMode)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: AppRadius.lg,
                              ),
                              child: Text(
                                'No work images added yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            )
                          else
                            Row(
                              children: List.generate(3, (index) {
                                final hasImage = index < _workImages.length;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: index < 2 ? AppSpacing.sm : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: (_isEditMode && !hasImage) ? _pickAndUploadImage : null,
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 100,
                                            decoration: BoxDecoration(
                                              color: AppColors.white,
                                              border: Border.all(
                                                color: AppColors.borderDefault,
                                              ),
                                              borderRadius: AppRadius.md,
                                            ),
                                            child: hasImage
                                                ? ClipRRect(
                                                    borderRadius: AppRadius.md,
                                                    child: Image.network(
                                                      _workImages[index],
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return Center(
                                                          child: CircularProgressIndicator(
                                                            value: loadingProgress.expectedTotalBytes != null
                                                                ? loadingProgress.cumulativeBytesLoaded /
                                                                    loadingProgress.expectedTotalBytes!
                                                                : null,
                                                            color: AppColors.primary,
                                                            strokeWidth: 2,
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Center(
                                                          child: Icon(
                                                            Icons.broken_image,
                                                            color: AppColors.textTertiary,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  )
                                                : Center(
                                                    child: _isUploading && index == _workImages.length
                                                        ? CircularProgressIndicator(
                                                            color: AppColors.primary,
                                                            strokeWidth: 2,
                                                          )
                                                        : (_isEditMode
                                                            ? Icon(
                                                                Icons.add,
                                                                size: 24,
                                                                color: AppColors.textTertiary,
                                                              )
                                                            : SizedBox.shrink()),
                                                  ),
                                          ),
                                          // Delete button for images (only in edit mode)
                                          if (hasImage && _isEditMode)
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => _removeWorkImage(index),
                                                child: Container(
                                                  padding: EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.error,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.close,
                                                    size: 16,
                                                    color: AppColors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.xl),
                      // Logout Button
                      Center(
                        child: TextButton(
                          onPressed: () async {
                            final shouldLogout = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.lg,
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
                                        borderRadius: AppRadius.md,
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

                            if (shouldLogout == true && mounted) {
                              await ref.read(authControllerProvider.notifier).signOut();
                              if (mounted) {
                                context.go('/auth/login');
                              }
                            }
                          },
                          child: Text(
                            'Logout',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
        borderRadius: AppRadius.md,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.borderDefault,
            ),
            child: avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      width: 70,
                      height: 70,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                            style: AppTypography.headlineMedium.copyWith(
                              fontWeight: AppTypography.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: AppTypography.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
          ),
          SizedBox(width: AppSpacing.md),
          // Name and Rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
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
          ),
        ],
      ),
    );
  }
}
