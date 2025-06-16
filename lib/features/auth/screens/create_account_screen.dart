import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/style_constants.dart';
import '../../../core/widgets/qwerty_overlay.dart';
import '../controllers/auth_controller.dart';
import 'dart:developer' as dev;

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _showQwertyOverlay({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool obscureText = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return QwertyOverlay(
          previewController: controller,
          obscureText: obscureText,
          onCharacterPressed: (char) {
            setState(() {
              controller.text += char;
            });
          },
          onBackspacePressed: () {
            setState(() {
              if (controller.text.isNotEmpty) {
                controller.text =
                    controller.text.substring(0, controller.text.length - 1);
              }
            });
          },
          onConfirmPressed: () {
            Navigator.pop(context);
            focusNode.unfocus();
          },
        );
      },
    ).whenComplete(() {
      if (mounted) {
        focusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 100.0, 24.0, 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  
                  // Create Account heading
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    'Unlock a World of Opportunities. Sign up now!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Email field
                  GestureDetector(
                    onTap: () {
                      _emailFocusNode.requestFocus();
                      _showQwertyOverlay(
                        context: context,
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                      );
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        decoration: const InputDecoration(
                          hintText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        readOnly: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Password field
                  GestureDetector(
                    onTap: () {
                      _passwordFocusNode.requestFocus();
                      _showQwertyOverlay(
                        context: context,
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: true,
                      );
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        readOnly: true,
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Confirm Password field
                  GestureDetector(
                    onTap: () {
                      _confirmPasswordFocusNode.requestFocus();
                      _showQwertyOverlay(
                        context: context,
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        obscureText: true,
                      );
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        readOnly: true,
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Password requirements
                  Text(
                    'Must include at least 8 characters',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Terms and Conditions checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center, 
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        activeColor: StyleConstants.taskerColorPrimary,
                        onChanged: (value) {
                          setState(() {
                            _agreedToTerms = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 8), 
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                            ),
                            children: const [
                              TextSpan(text: 'I have read and agree to '),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: StyleConstants.taskerColorPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Create Account button
                  ElevatedButton(
                    onPressed: (_agreedToTerms && !_isLoading)
                        ? () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                _isLoading = true;
                              });
                              
                              try {
                                final authController = ref.read(authControllerProvider.notifier);
                                
                                // Call Supabase signUp method
                                final response = await authController.signUp(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                );
                                
                                dev.log('Sign up response: ${response.session != null}, user: ${response.user?.id}');
                                
                                if (mounted) {
                                  // Navigate to OTP verification screen
                                  await context.push('/otp-verification', extra: {'email': _emailController.text.trim(), 'type': OtpType.signup});
                                }
                              } catch (e) {
                                dev.log('Error signing up: $e');
                                if (e is AuthException) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.message),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('An error occurred during sign up. Please try again.'),
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
                        : const Text('Create Account'),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Already have an account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: () {
                          context.go('/login');
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: StyleConstants.taskerColorPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
