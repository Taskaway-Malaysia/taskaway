import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskaway/core/constants/style_constants.dart';
import 'package:taskaway/core/widgets/numpad_overlay.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.type,
  });

  final String email;
  final OtpType type;

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  int _currentOtpIndex = 0;

  int _resendSeconds = 60;
  Timer? _timer;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
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
                }
              });
            }
          },
          onBackspacePressed: () {
            if (_currentOtpIndex >= 0) {
              setState(() {
                if (_controllers[_currentOtpIndex].text.isNotEmpty) {
                  _controllers[_currentOtpIndex].clear();
                } else if (_currentOtpIndex > 0) {
                  _currentOtpIndex--;
                  _controllers[_currentOtpIndex].clear();
                }
              });
            }
          },
          onConfirmPressed: () {
            Navigator.pop(context); // Close the numpad
            _verifyOtp();
          },
        );
      },
    );
  }

  Future<void> _verifyOtp() async {
    final authNotifier = ref.read(authControllerProvider.notifier);
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit code.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      await authNotifier.verifyOtp(
        email: widget.email,
        token: otp,
        type: widget.type,
      );
      // On success, GoRouter's redirect will handle navigation
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Code'),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Enter Verification Code',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter the verification code we just sent to \n${widget.email}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) {
                            return GestureDetector(
                              onTap: () => _showNumpad(context),
                              child: Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _currentOtpIndex == index
                                        ? StyleConstants.taskerColorPrimary
                                        : Colors.grey.shade300,
                                    width: _currentOtpIndex == index ? 2 : 1.0,
                                  ),
                                ),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    controller: _controllers[index],
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
                            onPressed: (_resendSeconds == 0 && !isLoading && !_isResending) ? () async {
                              setState(() {
                                _isResending = true;
                                _errorMessage = null;
                              });
                              try {
                                await ref.read(authControllerProvider.notifier).resendOtp(email: widget.email, type: widget.type);
                                setState(() {
                                  _resendSeconds = 60;
                                  _startResendTimer();
                                });
                              } on AuthException catch (e) {
                                setState(() {
                                  _errorMessage = e.message;
                                });
                              } finally {
                                setState(() {
                                  _isResending = false;
                                });
                              }
                            } : null,
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
                        const Spacer(),
                        ElevatedButton(
                          onPressed: isLoading ? null : _verifyOtp,
                          child: isLoading
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
                        const SizedBox(height: 16), // Padding at the bottom
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
