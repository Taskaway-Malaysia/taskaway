import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/style_constants.dart';
import '../../../core/constants/app_links.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';
import '../../../core/theme/app_radius.dart';

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
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate() && _agreedToTerms) {
      setState(() {
        _isLoading = true;
      });

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);

      try {
        final authController = ref.read(authControllerProvider.notifier);
        final response = await authController.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted && response.user != null) {
          router.go(
            '/otp-verification',
            extra: {
              'email': _emailController.text.trim(),
              'type': OtpType.signup
            },
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Colors.red,
            ),
          );
          if (e.message.contains('already exists') || e.message.contains('have an account')) {
            router.go('/login');
          }
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('An unexpected error occurred. Please try again.'),
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
    } else if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms & Conditions'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignUp() async {
    // TODO: Implement Google Sign-Up
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign-Up coming soon'),
      ),
    );
  }

  Future<void> _handleAppleSignUp() async {
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
            content: Text('An unexpected error occurred with Apple Sign-up.'),
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

  /// Launch URL in external browser or in-app webview
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 33),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 39),

                  // Logo
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFDFDFD),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/taskaway_logo_login.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Create Account heading
                  Text(
                    'Create your account',
                    style: AppTypography.headlineMedium,
                  ),

                  const SizedBox(height: 5),

                  // Subtitle
                  Text(
                    'Sign up to get started with Taskaway',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 21),

                  // Email field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: AppTypography.inputLabel,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Enter your email...',
                          hintStyle: AppTypography.inputHint,
                          prefixIcon: Icon(
                            Icons.mail_outline,
                            color: AppColors.textTertiary,
                            size: AppSpacing.iconMd,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E4E4),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E4E4),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(
                              color: Color(0xFFFFC333),
                              width: 1,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1,
                            ),
                          ),
                        ),
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
                    ],
                  ),

                  const SizedBox(height: 19),

                  // Password field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password',
                        style: AppTypography.inputLabel,
                      ),
                      SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Enter your password...',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF717680),
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF8F9098),
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF8F9098),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E4E4),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E4E4),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(
                              color: Color(0xFFFFC333),
                              width: 1,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1,
                            ),
                          ),
                        ),
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
                    ],
                  ),

                  const SizedBox(height: 19),

                  // Confirm Password field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Password',
                        style: AppTypography.inputLabel,
                      ),
                      SizedBox(height: 6),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Confirm your password...',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF717680),
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF8F9098),
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF8F9098),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E4E4),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E4E4),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(
                              color: Color(0xFFFFC333),
                              width: 1,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1,
                            ),
                          ),
                        ),
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
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Password requirements
                  Text(
                    'Must include at least 8 characters',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Terms and Conditions checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _agreedToTerms,
                          activeColor: const Color(0xFFFFC333),
                          side: const BorderSide(
                            color: Color(0xFFE4E4E4),
                            width: 1,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'I have read and agree to ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF717680),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _launchURL(AppLinks.termsAndConditions),
                              child: const Text(
                                'Terms & Conditions',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF717680),
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Text(
                              ' and ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF717680),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _launchURL(AppLinks.privacyPolicy),
                              child: const Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF717680),
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Create Account button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFDB5B),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smMd,
                          side: const BorderSide(
                            color: Color(0xFFFFC333),
                            width: 1,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: AppSpacing.xl,
                              width: AppSpacing.xl,
                              child: CircularProgressIndicator(
                                color: AppColors.textPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Create Account',
                              style: AppTypography.labelMedium,
                            ),
                    ),
                  ),

                  const SizedBox(height: 17),

                  // Or continue with divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE4E4E4),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Or continue with',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE4E4E4),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Apple sign up button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _handleAppleSignUp,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.black,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smMd,
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
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Google sign up button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _handleGoogleSignUp,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: const BorderSide(
                          color: Color(0xFFE4E4E4),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smMd,
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
                            style: AppTypography.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Already have an account
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTypography.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () {
                            context.go('/login');
                          },
                          child: Text(
                            'Login',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}