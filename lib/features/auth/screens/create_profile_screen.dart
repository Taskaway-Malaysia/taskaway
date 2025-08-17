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
            padding: const EdgeInsets.all(24.0),
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
                          color: Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 24),
                  // Correctly place the calls to field builder methods

                  // First name
                  Text(
                    'First name',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
                  // Last name
                  Text(
                    'Last name',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
                  // Date of birth
                  Text(
                    'Date of birth',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
                  // Postcode
                  Text(
                    'Postcode',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 16),
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
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'poster'
                                  ? StyleConstants.posterColorLight
                                  : Colors.white,
                              border: Border.all(
                                color: _selectedRole == 'poster'
                                    ? StyleConstants.posterColorPrimary
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(8),
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
                                        ? Colors.white
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('Give away tasks'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'tasker';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'tasker'
                                  ? StyleConstants.taskerColorLight
                                  : Colors.white,
                              border: Border.all(
                                color: _selectedRole == 'tasker'
                                    ? StyleConstants.taskerColorPrimary
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(8),
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
                                        ? Colors.white
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('Earn money'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                      const SizedBox(width: 8), // Optional: Add a small horizontal gap
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
                      const SizedBox(width: 8), // Optional: Add a small horizontal gap
                      Expanded(
                        // Removed Padding with top: 12
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.black87,
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_termsConsent && _selectedRole.isNotEmpty && !_isLoading)
                          ? () async {
                              if (_formKey.currentState!.validate()) {
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

                                  // Parse date and postcode safely
                                  final dobText = _dobController.text.trim();
                                  final DateTime? dateOfBirth = dobText.isNotEmpty
                                      ? DateFormat('dd/MM/yy').parse(dobText)
                                      : null;
                                  final int? postcode = int.tryParse(_postcodeController.text.trim());

                                  final Profile profile = Profile(
                                    id: currentUser.id,
                                    username: null, // Username is no longer collected in UI
                                    fullName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
                                    role: _selectedRole,
                                    dateOfBirth: dateOfBirth,
                                    postcode: postcode,
                                    createdAt: now,
                                    updatedAt: now,
                                  );

                                  // Convert to JSON. Fields like date_of_birth, postcode are NOT in taskaway_profiles table.
                                  final Map<String, dynamic> profileData = profile.toJson();

                                  // Insert profile into Supabase
                                  await Supabase.instance.client.from(DbConstants.profilesTable).insert(profileData);

                                  print('Profile created successfully for user: ${currentUser.id}');

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
                            }
                          : null,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Complete'),
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
