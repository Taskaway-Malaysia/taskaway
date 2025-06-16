import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/style_constants.dart';
import '../../../core/widgets/numpad_overlay.dart';
import '../controllers/auth_controller.dart';
import 'dart:developer' as dev;

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final OtpType type;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.type = OtpType.signup, // Default to signup for backward compatibility
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _currentOtpIndex = 0;

  int _resendSeconds = 60;
  Timer? _timer;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Request focus for the first OTP box initially to highlight it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  void _startResendTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _showNumpad(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return NumpadOverlay(
          confirmButtonText: 'Verify',
          onDigitPressed: (digit) {
            if (_currentOtpIndex < 6) {
              setState(() {
                _controllers[_currentOtpIndex].text = digit;
                if (_currentOtpIndex < 5) {
                  _currentOtpIndex++;
                  _focusNodes[_currentOtpIndex].requestFocus();
                } else {
                  // All fields filled, optionally auto-submit or enable verify
                  // For now, just keep focus on the last field
                  _focusNodes[_currentOtpIndex].requestFocus(); 
                }
              });
            }
          },
          onBackspacePressed: () {
            setState(() {
              if (_controllers[_currentOtpIndex].text.isNotEmpty) {
                _controllers[_currentOtpIndex].text = '';
              } else if (_currentOtpIndex > 0) {
                _currentOtpIndex--;
                _controllers[_currentOtpIndex].text = '';
              }
              _focusNodes[_currentOtpIndex].requestFocus();
            });
          },
          onConfirmPressed: () {
            Navigator.pop(context); // Close the numpad
            _verifyOtp();
          },
        );
      },
    ).whenComplete(() {
        // Ensure focus is correctly managed when bottom sheet closes
        if (mounted && _currentOtpIndex < _focusNodes.length) {
           _focusNodes[_currentOtpIndex].requestFocus();
        }
    });
  }

  Future<void> _handleResendOtp() async {
    if (_resendSeconds == 0 && !_isResending) {
      setState(() {
        _isResending = true;
        _errorMessage = null;
      });
      
      try {
        final authController = ref.read(authControllerProvider.notifier);
        
        await authController.resendOtp(
          email: widget.email,
          type: widget.type,
        );
        
        if (mounted) {
          setState(() {
            _resendSeconds = 60;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification code resent successfully'),
                backgroundColor: Colors.green,
              ),
            );
          });
          _startResendTimer();
        }
      } catch (e) {
        dev.log('Error resending OTP: $e');
        if (mounted) {
          setState(() {
            _errorMessage = e is AuthException 
                ? e.message 
                : 'Failed to resend verification code. Please try again.';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isResending = false;
          });
        }
      }
    }
  }
  
  Future<void> _verifyOtp() async {
    // Gather OTP from all text fields
    final otp = _controllers.map((controller) => controller.text).join('');
    
    // Validate OTP format
    if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit code';
      });
      return;
    }
    
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    
    try {
      final authController = ref.read(authControllerProvider.notifier);
      
      final response = await authController.verifyOtp(
        email: widget.email,
        token: otp,
        type: widget.type,
      );
      
      dev.log('OTP verification successful: ${response.session != null}');
      
      if (mounted) {
        if (widget.type == OtpType.recovery) {
          dev.log('Navigating to /change-password after recovery OTP verification.');
          context.pushReplacement('/change-password', extra: widget.email);
        } else {
          dev.log('Navigating to / after signup OTP verification to handle routing.');
          context.go('/');
        }
      }
    } catch (e) {
      dev.log('Error verifying OTP: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Invalid verification code. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'Verification Code',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter the verification code we just sent to\n${widget.email}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.black54,
                                height: 1.5,
                              ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentOtpIndex = index;
                                });
                                _focusNodes[index].requestFocus();
                                _showNumpad(context);
                              },
                              child: Container(
                                width: 46,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _focusNodes[index].hasFocus
                                        ? StyleConstants.posterColorPrimary
                                        : Colors.grey.shade300,
                                    width: _focusNodes[index].hasFocus ? 1.5 : 1.0,
                                  ),
                                ),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    readOnly: true,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 32),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        Center(
                          child: TextButton(
                            onPressed: (_resendSeconds == 0 && !_isResending) ? _handleResendOtp : null,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: _isResending
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _resendSeconds > 0
                                        ? 'Resend code in ${_resendSeconds}s'
                                        : 'Resend Code',
                                    style: TextStyle(
                                      color: _resendSeconds > 0
                                          ? Colors.grey
                                          : StyleConstants.taskerColorPrimary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 250), 
                        ElevatedButton(
                          onPressed: !_isVerifying ? _verifyOtp : null,
                          child: _isVerifying
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Verify'),
                        ),
                        const Spacer(), 
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
