import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Reusable banner widget to display bank verification status
/// Shows different UI based on verification status: unverified, pending, rejected, verified
class BankVerificationBanner extends StatelessWidget {
  final String? verificationStatus;
  final VoidCallback? onActionPressed;

  const BankVerificationBanner({
    super.key,
    required this.verificationStatus,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show banner if verified or status is null
    if (verificationStatus == 'verified' || verificationStatus == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIcon(),
                color: _getIconColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getTitle(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              _getMessage(),
              style: TextStyle(
                fontSize: 14,
                color: _getTextColor().withOpacity(0.9),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getIconColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Status: ${_getStatusLabel()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getIconColor(),
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onActionPressed ??
                      () => context.push('/profile/bank-details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getIconColor(),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(_getActionLabel()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (verificationStatus) {
      case 'unverified':
        return const Color(0xFFFFF3E0); // Orange 50
      case 'pending':
        return const Color(0xFFE3F2FD); // Blue 50
      case 'rejected':
        return const Color(0xFFFFEBEE); // Red 50
      default:
        return const Color(0xFFFFF3E0);
    }
  }

  Color _getBorderColor() {
    switch (verificationStatus) {
      case 'unverified':
        return const Color(0xFFFF9800); // Orange
      case 'pending':
        return const Color(0xFF2196F3); // Blue
      case 'rejected':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFFFF9800);
    }
  }

  Color _getIconColor() {
    switch (verificationStatus) {
      case 'unverified':
        return const Color(0xFFFF9800); // Orange
      case 'pending':
        return const Color(0xFF2196F3); // Blue
      case 'rejected':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFFFF9800);
    }
  }

  Color _getTextColor() {
    switch (verificationStatus) {
      case 'unverified':
        return const Color(0xFFE65100); // Dark Orange
      case 'pending':
        return const Color(0xFF0D47A1); // Dark Blue
      case 'rejected':
        return const Color(0xFFC62828); // Dark Red
      default:
        return const Color(0xFFE65100);
    }
  }

  IconData _getIcon() {
    switch (verificationStatus) {
      case 'unverified':
        return Icons.warning_amber_rounded;
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'rejected':
        return Icons.error_outline_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String _getTitle() {
    switch (verificationStatus) {
      case 'unverified':
        return 'Bank Verification Required';
      case 'pending':
        return 'Bank Verification in Progress';
      case 'rejected':
        return 'Bank Verification Failed';
      default:
        return 'Bank Verification Required';
    }
  }

  String _getMessage() {
    switch (verificationStatus) {
      case 'unverified':
        return 'Add your bank details to start applying for tasks and receive payments.';
      case 'pending':
        return 'We\'re reviewing your bank account details. You\'ll receive a notification once approved (typically within 24-48 hours).';
      case 'rejected':
        return 'Your bank verification was rejected. Please update your details and resubmit for verification.';
      default:
        return 'Add your bank details to start applying for tasks and receive payments.';
    }
  }

  String _getStatusLabel() {
    switch (verificationStatus) {
      case 'unverified':
        return 'Unverified';
      case 'pending':
        return 'Pending Approval';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  String _getActionLabel() {
    switch (verificationStatus) {
      case 'unverified':
        return 'Add Bank Details';
      case 'pending':
        return 'View Status';
      case 'rejected':
        return 'Update Details';
      default:
        return 'Add Bank Details';
    }
  }
}
