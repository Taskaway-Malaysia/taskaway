import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/skills_input.dart';
import '../widgets/image_picker_grid.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _aboutController = TextEditingController();
  
  List<String> _skills = [];
  List<String> _workImages = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    if (!mounted) return;
    
    try {
      final profileAsync = ref.read(currentProfileProvider);
      final user = ref.read(currentUserProvider);
      
      profileAsync.when(
        data: (profile) {
          if (mounted && profile != null && !_isInitialized) {
            setState(() {
              _nameController.text = profile.fullName;
              _locationController.text = user?.userMetadata?['location']?.toString() ?? '';
              _bioController.text = profile.bio ?? '';
              _aboutController.text = profile.about ?? '';
              _skills = List.from(profile.skills ?? []);
              _workImages = List.from(profile.myWorks ?? []);
              _isInitialized = true;
            });
          } else if (mounted && user != null && !_isInitialized) {
            setState(() {
              _nameController.text = user.userMetadata?['name']?.toString() ?? '';
              _locationController.text = user.userMetadata?['location']?.toString() ?? '';
              _bioController.text = user.userMetadata?['bio']?.toString() ?? '';
              _aboutController.text = user.userMetadata?['about']?.toString() ?? '';
              _isInitialized = true;
            });
          }
        },
        loading: () {},
        error: (_, __) {
          if (mounted && user != null && !_isInitialized) {
            setState(() {
              _nameController.text = user.userMetadata?['name']?.toString() ?? '';
              _locationController.text = user.userMetadata?['location']?.toString() ?? '';
              _bioController.text = user.userMetadata?['bio']?.toString() ?? '';
              _aboutController.text = user.userMetadata?['about']?.toString() ?? '';
              _isInitialized = true;
            });
          }
        },
      );
    } catch (e) {
      // Fallback in case of any provider errors
      if (mounted && !_isInitialized) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = ref.read(profileControllerProvider);
      
      // Save all profile data in one go
      await controller.updateProfile(
        userId: user.id,
        fullName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        about: _aboutController.text.trim(),
        skills: _skills,
        myWorks: _workImages,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home/profile');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety check to ensure providers are accessible
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Purple header as SliverAppBar
          SliverAppBar(
            backgroundColor: AppColors.posterPrimary,
            elevation: 0,
            pinned: false,
            floating: false,
            expandedHeight: 80,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: AppColors.white),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home/profile');
                }
              },
            ),
            flexibleSpace: const FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile avatar with edit button
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey.shade300,
                            child: Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text.length >= 2
                                      ? _nameController.text.substring(0, 2).toUpperCase()
                                      : _nameController.text.substring(0, 1).toUpperCase()
                                  : 'IR',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.posterPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.edit,
                                  color: AppColors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppSpacing.xxxl),

                    // PUBLIC INFORMATION Section
                    Text(
                      'PUBLIC INFORMATION',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),

                    SizedBox(height: AppSpacing.lg),

                    // Name field
                    Text(
                      'Name',
                      style: AppTypography.labelLarge,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.md,
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.md,
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.md,
                          borderSide: const BorderSide(color: AppColors.posterPrimary),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      onChanged: (value) => setState(() {}), // Update avatar
                    ),

                    SizedBox(height: AppSpacing.lg),

                    // Location field
                    Text(
                      'Location',
                      style: AppTypography.labelLarge,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'Enter your location',
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.md,
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.md,
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.md,
                          borderSide: const BorderSide(color: AppColors.posterPrimary),
                        ),
                      ),
                    ),

                    SizedBox(height: AppSpacing.lg),

                    // Bio field
                    Text(
                      'Bio',
                      style: AppTypography.labelLarge,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Craft your bio here! Let others know who you are in a few words.',
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.md,
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.md,
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.md,
                          borderSide: const BorderSide(color: AppColors.posterPrimary),
                        ),
                      ),
                    ),

                    SizedBox(height: AppSpacing.lg),

                    // About field
                    Text(
                      'About',
                      style: AppTypography.labelLarge,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _aboutController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'Tell people more about yourself, your experience, and what you do...',
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.md,
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.md,
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.md,
                          borderSide: const BorderSide(color: AppColors.posterPrimary),
                        ),
                      ),
                    ),

                    SizedBox(height: AppSpacing.xxxl),

                    // ADDITIONAL INFORMATION Section
                    Text(
                      'ADDITIONAL INFORMATION',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),

                    SizedBox(height: AppSpacing.lg),

                    // Skills section
                    Text(
                      'Skills',
                      style: AppTypography.labelLarge,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: AppRadius.md,
                      ),
                      child: SkillsInput(
                        initialSkills: _skills,
                        onSkillsChanged: (newSkills) {
                          setState(() {
                            _skills = newSkills;
                          });
                        },
                      ),
                    ),

                    SizedBox(height: AppSpacing.lg),

                    // My Works section
                    Text(
                      'My works',
                      style: AppTypography.labelLarge,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: AppRadius.md,
                      ),
                      child: Builder(
                        builder: (context) {
                          final currentUser = ref.read(currentUserProvider);
                          return ImagePickerGrid(
                            initialImages: _workImages,
                            userId: currentUser?.id ?? '',
                            onImagesChanged: (newImages) {
                              setState(() {
                                _workImages = newImages;
                              });
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.posterPrimary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.md,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: AppTypography.labelLarge,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}