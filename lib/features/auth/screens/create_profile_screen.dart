import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/style_constants.dart';
import '../../../core/constants/db_constants.dart';
import '../../../core/widgets/numpad_overlay.dart';
import '../../../core/widgets/qwerty_overlay.dart';
import '../controllers/auth_controller.dart';
import '../models/profile.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import 'dart:developer' as dev;

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _postcodeFocusNode = FocusNode();

  String _selectedRole = ''; // 'poster' or 'tasker'
  bool _marketingConsent = false;
  bool _termsConsent = false;
  bool _isLoading = false;

  // APPLE-REVIEW: Check if user signed in with Apple
  bool _isAppleUser = false;

  @override
  void initState() {
    super.initState();
    _checkIfAppleUser();
  }

  void _checkIfAppleUser() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      final authProvider = currentUser.userMetadata?['auth_provider'] as String?;
      setState(() {
        _isAppleUser = authProvider == 'apple';
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _postcodeController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _postcodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now()
          .subtract(const Duration(days: 365 * 18)), // Default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: StyleConstants.posterColorPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yy').format(picked);
      });
    }
  }

  void _showNumpadForPostcode(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return NumpadOverlay(
          previewController: _postcodeController,
          confirmButtonText: 'Done',
          onDigitPressed: (digit) {
            setState(() {
              _postcodeController.text += digit;
            });
          },
          onBackspacePressed: () {
            setState(() {
              if (_postcodeController.text.isNotEmpty) {
                _postcodeController.text = _postcodeController.text
                    .substring(0, _postcodeController.text.length - 1);
              }
            });
          },
          onConfirmPressed: () {
            Navigator.pop(context); // Close the numpad
            _postcodeFocusNode.unfocus(); // Unfocus after confirming
          },
        );
      },
    ).whenComplete(() {
       if (mounted) {
         _postcodeFocusNode.unfocus();
       }
    });
  }

  void _showQwertyForFirstName(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return QwertyOverlay(
          previewController: _firstNameController,
          onCharacterPressed: (char) {
            setState(() {
              _firstNameController.text += char;
            });
          },
          onBackspacePressed: () {
            setState(() {
              if (_firstNameController.text.isNotEmpty) {
                _firstNameController.text = _firstNameController.text
                    .substring(0, _firstNameController.text.length - 1);
              }
            });
          },
          onConfirmPressed: () {
            Navigator.pop(context);
            _firstNameFocusNode.unfocus();
          },
        );
      },
    ).whenComplete(() {
      if (mounted) {
        _firstNameFocusNode.unfocus();
      }
    });
  }

  void _showQwertyForLastName(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return QwertyOverlay(
          previewController: _lastNameController,
          onCharacterPressed: (char) {
            setState(() {
              _lastNameController.text += char;
            });
          },
          onBackspacePressed: () {
            setState(() {
              if (_lastNameController.text.isNotEmpty) {
                _lastNameController.text = _lastNameController.text
                    .substring(0, _lastNameController.text.length - 1);
              }
            });
          },
          onConfirmPressed: () {
            Navigator.pop(context);
            _lastNameFocusNode.unfocus();
          },
        );
      },
    ).whenComplete(() {
      if (mounted) {
        _lastNameFocusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Create your profile heading
                  Text(
                    'Create your profile',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  // APPLE-REVIEW: Hide name/DOB/postcode fields for Apple Sign In users
                  // Apple already provides name via Authentication Services
                  if (!_isAppleUser) ...[
                    // First name
                    Text(
                      'First name',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: () {
                        _firstNameFocusNode.requestFocus();
                        _showQwertyForFirstName(context);
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _firstNameController,
                          focusNode: _firstNameFocusNode,
                          decoration: const InputDecoration(
                            hintText: 'First name',
                          ),
                          readOnly: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    // Last name
                    Text(
                      'Last name',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: () {
                        _lastNameFocusNode.requestFocus();
                        _showQwertyForLastName(context);
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _lastNameController,
                          focusNode: _lastNameFocusNode,
                          decoration: const InputDecoration(
                            hintText: 'Last name',
                          ),
                          readOnly: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    // Date of birth
                    Text(
                      'Date of birth',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _dobController,
                      decoration: const InputDecoration(
                        hintText: 'DD/MM/YY',
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your date of birth';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSpacing.lg),
                    // Postcode
                    Text(
                      'Postcode',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: () {
                        _postcodeFocusNode.requestFocus();
                        _showNumpadForPostcode(context);
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _postcodeController,
                          focusNode: _postcodeFocusNode,
                          decoration: const InputDecoration(
                            hintText: 'Postcode',
                          ),
                          readOnly: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your postcode';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxl),
                  ],
                  // What is your goal
                  Text(
                    'What is your goal here on Taskaway?',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  // Role selection
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'poster';
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'poster'
                                  ? StyleConstants.posterColorLight
                                  : AppColors.white,
                              border: Border.all(
                                color: _selectedRole == 'poster'
                                    ? StyleConstants.posterColorPrimary
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: AppRadius.md,
                            ),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _selectedRole == 'poster'
                                        ? StyleConstants
                                            .posterColorPrimary
                                        : Colors.grey.shade200,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: _selectedRole == 'poster'
                                        ? AppColors.white
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.sm),
                                Text('Give away tasks'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'tasker';
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'tasker'
                                  ? StyleConstants.taskerColorLight
                                  : AppColors.white,
                              border: Border.all(
                                color: _selectedRole == 'tasker'
                                    ? StyleConstants.taskerColorPrimary
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: AppRadius.md,
                            ),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _selectedRole == 'tasker'
                                        ? StyleConstants
                                            .taskerColorPrimary
                                        : Colors.grey.shade200,
                                  ),
                                  child: Icon(
                                    Icons.attach_money,
                                    color: _selectedRole == 'tasker'
                                        ? AppColors.white
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.sm),
                                Text('Earn money'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  // Marketing consent
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // Changed to center
                    children: [
                      Checkbox(
                        value: _marketingConsent,
                        activeColor:
                            StyleConstants.posterColorPrimary,
                        onChanged: (value) {
                          setState(() {
                            _marketingConsent = value ?? false;
                          });
                        },
                      ),
                      SizedBox(width: AppSpacing.sm), // Optional: Add a small horizontal gap
                      Expanded(
                        // Removed Padding with top: 12
                        child: Text(
                          'I agree to receive product updates, marketing materials and special offers via email, SMS, and push notifications.',
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  // Terms consent
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // Changed to center
                    children: [
                      Checkbox(
                        value: _termsConsent,
                        activeColor:
                            StyleConstants.posterColorPrimary,
                        onChanged: (value) {
                          setState(() {
                            _termsConsent = value ?? false;
                          });
                        },
                      ),
                      SizedBox(width: AppSpacing.sm), // Optional: Add a small horizontal gap
                      Expanded(
                        // Removed Padding with top: 12
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                            children: const [
                              TextSpan(
                                  text:
                                      'I agree to the Taskaway Malaysia\'s '),
                              TextSpan(
                                text:
                                    'Term & Conditions, Community Guidelines and Privacy Policy',
                                style: TextStyle(
                                  color: StyleConstants
                                      .taskerColorPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_termsConsent && _selectedRole.isNotEmpty && !_isLoading)
                          ? () async {
                              // APPLE-REVIEW: Skip form validation for Apple users
                              // Apple users don't have name/DOB/postcode fields to validate
                              if (!_isAppleUser && !_formKey.currentState!.validate()) {
                                return;
                              }

                              setState(() {
                                _isLoading = true;
                              });

                              // Capture context-dependent objects before the async gap.
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final router = GoRouter.of(context);

                              try {
                                final authController = ref.read(authControllerProvider.notifier);
                                final currentUser = authController.currentUser;

                                if (currentUser == null) {
                                  throw Exception('User not authenticated');
                                }

                                final now = DateTime.now().toUtc();

                                // APPLE-REVIEW: Different handling for Apple users vs regular users
                                String fullName;
                                DateTime? dateOfBirth;
                                int? postcode;

                                if (_isAppleUser) {
                                  // Apple users: Use existing fullName from profile created by signInWithApple()
                                  // dateOfBirth and postcode remain NULL (not required for Apple users)
                                  fullName = currentUser.userMetadata?['full_name'] as String? ??
                                             currentUser.email?.split('@').first ??
                                             'Apple User';
                                  dateOfBirth = null;
                                  postcode = null;
                                  print('[Create Profile] Apple user: Using existing fullName: $fullName');
                                } else {
                                  // Regular users: Parse from form fields
                                  fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
                                  final dobText = _dobController.text.trim();
                                  dateOfBirth = dobText.isNotEmpty
                                      ? DateFormat('dd/MM/yy').parse(dobText)
                                      : null;
                                  postcode = int.tryParse(_postcodeController.text.trim());
                                }

                                final Profile profile = Profile(
                                  id: currentUser.id,
                                  username: null, // Username is no longer collected in UI
                                  fullName: fullName,
                                  role: _selectedRole,
                                  dateOfBirth: dateOfBirth,
                                  postcode: postcode,
                                  createdAt: now,
                                  updatedAt: now,
                                );

                                // Convert to JSON. Fields like date_of_birth, postcode are NOT in taskaway_profiles table.
                                final Map<String, dynamic> profileData = profile.toJson();

                                // TASK-NEW: Update existing profile instead of insert
                                // The auto-profile trigger already created a basic profile on signup
                                // Now we just need to update it with the user's additional details
                                await Supabase.instance.client
                                    .from(DbConstants.profilesTable)
                                    .update(profileData)
                                    .eq('id', currentUser.id);

                                print('Profile updated successfully for user: ${currentUser.id}');

                                  if (mounted) {
                                    // Navigate to success screen using go() instead of push()
                                    // This ensures we replace the current route instead of stacking
                                    router.go('/signup-success');
                                  }
                                } catch (e) {
                                  print('Error creating profile: $e');
                                  if (mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Error creating profile: ${e.toString()}'),
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
                          : null,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text('Complete'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
