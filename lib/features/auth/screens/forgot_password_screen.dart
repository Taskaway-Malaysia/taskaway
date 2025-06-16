import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskaway/core/constants/style_constants.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/core/widgets/qwerty_overlay.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final authController = ref.read(authControllerProvider.notifier);
      
      try {
        await authController.sendPasswordResetEmail(_emailController.text.trim());
        if (mounted) {
          await context.push('/otp-verification', extra: {
            'email': _emailController.text.trim(),
            'type': OtpType.recovery,
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Forgot Password?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No worries, we\'ve got you covered.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                      readOnly: true,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => QwertyOverlay(
                            previewController: _emailController,
                            onCharacterPressed: (char) {
                              _emailController.text += char;
                            },
                            onBackspacePressed: () {
                              if (_emailController.text.isNotEmpty) {
                                _emailController.text = _emailController.text
                                    .substring(0, _emailController.text.length - 1);
                              }
                            },
                            onConfirmPressed: () {
                              Navigator.pop(context); // Close the overlay
                            },
                            confirmButtonText: 'Done',
                          ),
                        );
                      },
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We will send you a code to reset your password. If you have any issues, contact admin@taskawayasia.com',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 350),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendResetLink,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Confirm'),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Back to login',
                        style: TextStyle(
                          color: StyleConstants.taskerColorPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
