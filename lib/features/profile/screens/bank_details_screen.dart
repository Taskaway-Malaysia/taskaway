import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/theme/app_colors.dart';
import 'package:taskaway/features/auth/controllers/auth_controller.dart';
import 'package:taskaway/features/auth/models/profile.dart';
import 'package:taskaway/core/services/supabase_service.dart';

/// Screen for managing bank account details and verification
/// Allows taskers to add/update bank information and track verification status
class BankDetailsScreen extends ConsumerStatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  ConsumerState<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();

  String? _selectedBank;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // List of major Malaysian banks
  final List<String> _malaysianBanks = [
    'Maybank',
    'CIMB Bank',
    'Public Bank',
    'RHB Bank',
    'Hong Leong Bank',
    'AmBank',
    'Bank Islam',
    'Bank Rakyat',
    'OCBC Bank',
    'HSBC Bank',
    'Standard Chartered',
    'Affin Bank',
    'Alliance Bank',
    'UOB Bank',
    'Bank Muamalat',
    'BSN (Bank Simpanan Nasional)',
    'MBSB Bank',
    'Agro Bank',
  ];

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    super.dispose();
  }

  Future<void> _loadBankDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileAsync = ref.read(currentProfileProvider);
      final profile = profileAsync.asData?.value;

      if (profile != null) {
        setState(() {
          _selectedBank = profile.bankName;
          _accountNumberController.text = profile.bankAccountNumber ?? '';
          _accountHolderNameController.text = profile.bankAccountHolderName ?? '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load bank details: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBankDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final profileAsync = ref.read(currentProfileProvider);
      final profile = profileAsync.asData?.value;

      if (profile == null) {
        throw Exception('User profile not found');
      }

      final supabase = SupabaseService.client;

      // Determine new verification status
      // If previously unverified or rejected, set to pending
      // If already pending or verified, keep the same status
      String newStatus = profile.bankVerificationStatus ?? 'unverified';

      if (newStatus == 'unverified' || newStatus == 'rejected') {
        newStatus = 'pending';
      }

      // Update bank details in database
      await supabase.from('taskaway_profiles').update({
        'bank_name': _selectedBank,
        'bank_account_number': _accountNumberController.text.trim(),
        'bank_account_holder_name': _accountHolderNameController.text.trim(),
        'bank_verification_status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', profile.id);

      // Invalidate profile provider to refresh data
      ref.invalidate(currentProfileProvider);

      setState(() {
        _successMessage = newStatus == 'pending'
            ? 'Bank details submitted for verification. You will be notified once approved (typically within 24-48 hours).'
            : 'Bank details updated successfully.';
      });

      // Show success dialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(_successMessage!),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop(); // Return to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save bank details: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.asData?.value;
    final verificationStatus = profile?.bankVerificationStatus;

    // Determine if form should be editable
    final isEditable = verificationStatus != 'verified' && verificationStatus != 'pending';

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Bank Account Details'),
        elevation: 0,
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.primaryBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verification Status Banner
                    _buildStatusBanner(verificationStatus),
                    const SizedBox(height: 24),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your bank account will be used to receive task payments via manual payout after task completion.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bank Name Dropdown
                    const Text(
                      'Bank Name',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedBank,
                      decoration: InputDecoration(
                        hintText: 'Select your bank',
                        filled: true,
                        fillColor: isEditable ? AppColors.backgroundGray : Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderDefault),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderDefault),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderDefault),
                        ),
                      ),
                      items: _malaysianBanks.map((bank) {
                        return DropdownMenuItem(
                          value: bank,
                          child: Text(bank),
                        );
                      }).toList(),
                      onChanged: isEditable
                          ? (value) {
                              setState(() {
                                _selectedBank = value;
                              });
                            }
                          : null,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a bank';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Account Number
                    const Text(
                      'Account Number',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accountNumberController,
                      enabled: isEditable,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(20),
                      ],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryBlack,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your account number',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: isEditable ? AppColors.backgroundGray : Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderDefault),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderDefault),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderDefault),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderDefault),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your account number';
                        }
                        if (value.length < 8) {
                          return 'Account number must be at least 8 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Account Holder Name
                    const Text(
                      'Account Holder Name',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accountHolderNameController,
                      enabled: isEditable,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryBlack,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter account holder name (as per bank)',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: isEditable ? AppColors.backgroundGray : Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderDefault),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderDefault),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderDefault),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderDefault),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter account holder name';
                        }
                        if (value.length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Important Note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Important: Ensure your account details are accurate. Incorrect information may delay payment processing.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: AppColors.errorRed),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: AppColors.errorRed),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Submit Button
                    if (isEditable)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveBankDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryYellow,
                            foregroundColor: AppColors.primaryBlack,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                color: AppColors.primaryYellowDark,
                                width: 1,
                              ),
                            ),
                          ),
                          child: _isSaving
                              ? CircularProgressIndicator(color: AppColors.primaryBlack)
                              : Text(
                                  verificationStatus == 'rejected'
                                      ? 'Resubmit for Verification'
                                      : 'Submit for Verification',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusBanner(String? status) {
    if (status == null || status == 'unverified') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF9800), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: const Color(0xFFFF9800), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bank Account Not Verified',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add your bank details below to start receiving task payments.',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFFE65100).withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2196F3), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty_rounded, color: const Color(0xFF2196F3), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification in Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your bank account is being reviewed. You\'ll be notified once approved (typically within 24-48 hours).',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF0D47A1).withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (status == 'rejected') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF44336), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: const Color(0xFFF44336), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification Failed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your bank verification was rejected. Please update your details and resubmit.',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFFC62828).withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (status == 'verified') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: const Color(0xFF4CAF50), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bank Account Verified',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your bank account is verified and ready to receive task payments.',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF2E7D32).withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
