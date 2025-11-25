import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        // Log login attempt
        print('=== LOGIN ATTEMPT ===');
        print('Email: $email');
        print('Password length: ${password.length} characters');
        print('Mounted: $mounted');

        final authController = ref.read(authControllerProvider.notifier);
        print('Auth controller loaded');

        print('Calling signIn...');
        final response = await authController.signIn(
          email: email,
          password: password,
        );

        print('SignIn response received:');
        print('  User ID: ${response.user?.id}');
        print('  User email: ${response.user?.email}');
        print('  Session exists: ${response.session != null}');

        if (mounted) {
          print('Widget still mounted, navigating to /home/browse');
          router.go('/home/browse');
          print('Navigation to /home/browse completed');
        } else {
          print('Widget NOT mounted after login, skipping navigation');
        }
      } on AuthException catch (e) {
        print('=== LOGIN AUTH EXCEPTION ===');
        print('Message: ${e.message}');
        print('Stack trace: ${StackTrace.current}');

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        print('=== LOGIN UNEXPECTED ERROR ===');
        print('Error: $e');
        print('Type: ${e.runtimeType}');
        print('Stack trace: ${StackTrace.current}');

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('An unexpected error occurred.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        print('=== LOGIN ATTEMPT FINISHED ===');
        print('Loading: false');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    // TODO: Implement Google Sign-In
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign-In coming soon'),
      ),
    );
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      final authController = ref.read(authControllerProvider.notifier);
      final response = await authController.signInWithApple();

      if (mounted && response.user != null) {
        router.go('/home/browse');
      }
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
            content: Text('An unexpected error occurred with Apple Sign-in.'),
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
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xxxl * 1.2),

                  // Welcome text
                  Text(
                    'Welcome to Taskaway',
                    style: AppTypography.headlineMedium,
                  ),

                  SizedBox(height: AppSpacing.xs),

                  // Subtitle
                  Text(
                    'Please enter your email and password to continue',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  SizedBox(height: AppSpacing.xl),

                  // Email field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: AppTypography.inputLabel,
                      ),
                      SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTypography.input,
                        decoration: InputDecoration(
                          hintText: 'Enter your email...',
                          hintStyle: AppTypography.inputHint,
                          prefixIcon: Icon(
                            Icons.mail_outline,
                            color: AppColors.textTertiary,
                            size: AppSpacing.iconMd,
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm + 2,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            borderSide: BorderSide(
                              color: AppColors.borderDefault,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            borderSide: BorderSide(
                              color: AppColors.borderDefault,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 1,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            borderSide: BorderSide(
                              color: AppColors.error,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            borderSide: BorderSide(
                              color: AppColors.error,
                              width: 1,
                            ),
                          ),
                        ),
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
                    ],
                  ),

                  SizedBox(height: AppSpacing.lg),

                  // Password field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password',
                        style: AppTypography.inputLabel,
                      ),
                      SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: AppTypography.input,
                        decoration: InputDecoration(
                          hintText: 'Enter your password...',
                          hintStyle: AppTypography.inputHint,
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: AppColors.textTertiary,
                            size: AppSpacing.iconMd,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textTertiary,
                              size: AppSpacing.iconMd,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm + 2,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            borderSide: BorderSide(
                              color: AppColors.borderDefault,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            borderSide: BorderSide(
                              color: AppColors.borderDefault,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 1,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            borderSide: BorderSide(
                              color: AppColors.error,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            borderSide: BorderSide(
                              color: AppColors.error,
                              width: 1,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.md),

                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        context.go('/forgot-password');
                      },
                      child: Text(
                        'Forgot Password?',
                        style: AppTypography.captionMedium.copyWith(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.underline,
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.lg),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.gray900,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          side: BorderSide(
                            color: AppColors.primary,
                            width: 1,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: AppSpacing.iconMd,
                              width: AppSpacing.iconMd,
                              child: CircularProgressIndicator(
                                color: AppColors.gray900,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Continue',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: AppTypography.semiBold,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.lg),

                  // Or continue with divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.borderDefault,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          'Or continue with',
                          style: AppTypography.captionMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.borderDefault,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.md),

                  // Apple sign in button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _handleAppleSignIn,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.black,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.apple,
                            size: 20,
                            color: Colors.white,
                          ),
                          SizedBox(width: AppSpacing.md),
                          Text(
                            'Continue with Apple',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: AppTypography.medium,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.md),

                  // Google sign in button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.gray900,
                        side: BorderSide(
                          color: AppColors.borderDefault,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google_logo.png',
                            width: 18,
                            height: 18,
                          ),
                          SizedBox(width: AppSpacing.md),
                          Text(
                            'Continue with Google',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: AppTypography.medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.xxxl * 2.7),

                  // Don't have an account? Sign Up
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.gray900,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.go('/create-account');
                          },
                          child: Text(
                            'Sign Up',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppSpacing.xxxl * 1.25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}