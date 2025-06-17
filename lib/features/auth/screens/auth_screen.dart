import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/style_constants.dart';
import '../../../core/constants/asset_constants.dart';
import '../../../core/widgets/qwerty_overlay.dart';
import '../controllers/auth_controller.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'dart:developer' as dev;

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
            padding: const EdgeInsets.all(24.0),
            child: Form( // Wrapped with Form widget
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Image.asset(
                      AssetConstants.logoPath,
                      height: 100,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Welcome back text
                Text(
                  'Welcome back,',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Login to get started
                Text(
                  'Login to Get Started',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        if (!value.contains('@')) {
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
                
                const SizedBox(height: 16),
                
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: StyleConstants.taskerColorPrimary,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            try {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .signIn(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                  );
                              // Invalidate the authStateProvider to ensure listeners pick up the change.
                              ref.invalidate(authStateProvider);

                              // Diagnostic: Check auth state after a brief delay and attempt to re-trigger splash
                              await Future.delayed(const Duration(milliseconds: 200));
                              final currentUserNow = ref.read(currentUserProvider);
                              final authStateValue = ref.read(authStateProvider).value;
                              dev.log('AuthScreen: Post-login check. CurrentUser: ${currentUserNow?.id}, AuthState Event: ${authStateValue?.event}');

                              if (mounted && currentUserNow != null) {
                                dev.log('AuthScreen: User confirmed authenticated, navigating to / to re-trigger SplashScreen logic.');
                                context.go('/');
                              } else {
                                dev.log('AuthScreen: Post-login check. User still null or state not updated.');
                              }
                              // Navigation is ideally handled by AuthState listener in Splash Screen
                            } on AuthException catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.message),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
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
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Login'),
                ),
                
                const SizedBox(height: 16),
                
                // Explore as guest
                OutlinedButton(
                  onPressed: () {
                    ref.read(isGuestModeProvider.notifier).state = true;
                    context.go('/home/browse');
                    dev.log('Explore as Guest pressed, guest mode activated');
                  },
                  child: const Text('Explore as Guest'),
                ),
                
                const SizedBox(height: 80),
                
                // Don't have an account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        context.go('/create-account');
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: StyleConstants.taskerColorPrimary,
                          fontWeight: FontWeight.bold,
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