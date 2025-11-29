import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/style_constants.dart';
import '../../../core/constants/asset_constants.dart';
import '../../../core/widgets/qwerty_overlay.dart';
import '../controllers/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Added form key
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false; // Added loading state

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
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
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Form( // Wrapped with Form widget
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                    child: Image.asset(
                      AssetConstants.logoPath,
                      height: 100,
                    ),
                  ),
                ),

                SizedBox(height: AppSpacing.xxl),

                // Welcome back text
                Text(
                  'Welcome back,',
                  style: AppTypography.headlineMedium,
                ),

                SizedBox(height: AppSpacing.sm),

                // Login to get started
                Text(
                  'Login to Get Started',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                SizedBox(height: AppSpacing.xxxl),
                
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
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ),
                ),

                SizedBox(height: AppSpacing.lg),

                // Password field
                GestureDetector(
                  onTap: () {
                    _passwordFocusNode.requestFocus();
                    _showQwertyOverlay(
                      context: context,
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
                    );
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                  ),
                ),

                SizedBox(height: AppSpacing.lg),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      'Forgot Password?',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: AppSpacing.xxl),
                
                // Login button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });

                            // Capture context-dependent objects before the async gap.
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final router = GoRouter.of(context);

                            try {
                              final authController = ref.read(authControllerProvider.notifier);
                              final response = await authController.signIn(
                                email: _emailController.text.trim(),
                                password: _passwordController.text,
                              );

                              // Post-login checks and navigation
                              print('AuthScreen: Login successful. Response user: ${response.user?.id}');
                              final currentUserNow = ref.read(currentUserProvider);
                              final authStateValue = ref.read(authStateProvider).value;
                              print('AuthScreen: Post-login check. CurrentUser: ${currentUserNow?.id}, AuthState Event: ${authStateValue?.event}');

                              if (mounted && currentUserNow != null) {
                                print('AuthScreen: User confirmed authenticated, navigating to / (Landing Screen).');
                                router.go('/');
                              } else {
                                print('AuthScreen: Post-login check. User still null or state not updated.');
                              }
                              // Navigation is ideally handled by AuthState listener in Landing Screen
                            } on AuthException catch (e) {
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(e.message),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('An unexpected error occurred.'),
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
                        },
                  child: _isLoading
                      ? SizedBox(
                          height: AppSpacing.xl,
                          width: AppSpacing.xl,
                          child: CircularProgressIndicator(
                            color: AppColors.textInverted,
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Login', style: AppTypography.labelLarge),
                ),

                // APPLE-REVIEW: Removed "Explore as guest" button
                // Reason: Guest mode not fully functional (RLS blocking or empty data)
                // Better UX: Require sign up/login to use the app
                // SizedBox(height: AppSpacing.lg),
                // OutlinedButton(
                //   onPressed: () {
                //     ref.read(isGuestModeProvider.notifier).state = true;
                //     context.go('/home/browse');
                //     print('Explore as Guest pressed, guest mode activated');
                //   },
                //   child: Text('Explore as Guest', style: AppTypography.labelLarge),
                // ),

                SizedBox(height: AppSpacing.massive),

                // Don't have an account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: AppTypography.bodyMedium),
                    TextButton(
                      onPressed: () {
                        context.go('/create-account');
                      },
                      child: Text(
                        'Sign Up',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ], // Closes Column children
            ), // Closes Form
          ), // Closes Padding
        ), // Closes SingleChildScrollView
      ), // Closes SafeArea
    )); // Closes Scaffold & statement
  } // build method closing brace
}