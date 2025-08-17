/// Enum for supported payment method types
enum PaymentMethodType {
  card('card', 'Credit/Debit Card', true),
  fpx('fpx', 'FPX Online Banking', false),
  grabpay('grabpay', 'GrabPay', false);

  final String value;
  final String displayName;
  final bool supportsManualCapture;

  const PaymentMethodType(this.value, this.displayName, this.supportsManualCapture);

  static PaymentMethodType fromString(String value) {
    return PaymentMethodType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PaymentMethodType.card,
    );
  }

  String get description {
    switch (this) {
      case PaymentMethodType.card:
        return 'Payment will be held until task completion';
      case PaymentMethodType.fpx:
        return 'Instant payment via Malaysian online banking';
      case PaymentMethodType.grabpay:
        return 'Instant payment via GrabPay wallet';
    }
  }

  String get iconAsset {
    switch (this) {
      case PaymentMethodType.card:
        return 'assets/icons/credit_card.png';
      case PaymentMethodType.fpx:
        return 'assets/icons/fpx.png';
      case PaymentMethodType.grabpay:
        return 'assets/icons/grabpay.png';
    }
  }
}

/// Malaysian banks available for FPX payments
class FPXBank {
  final String code;
  final String name;
  final String shortName;

  const FPXBank({
    required this.code,
    required this.name,
    required this.shortName,
  });
}

const List<FPXBank> fpxBanks = [
  FPXBank(code: 'maybank2u', name: 'Maybank2U', shortName: 'Maybank'),
  FPXBank(code: 'cimb', name: 'CIMB Clicks', shortName: 'CIMB'),
  FPXBank(code: 'public_bank', name: 'Public Bank', shortName: 'Public Bank'),
  FPXBank(code: 'rhb', name: 'RHB Now', shortName: 'RHB'),
  FPXBank(code: 'hong_leong_bank', name: 'Hong Leong Connect', shortName: 'Hong Leong'),
  FPXBank(code: 'ambank', name: 'AmBank', shortName: 'AmBank'),
  FPXBank(code: 'bank_islam', name: 'Bank Islam', shortName: 'Bank Islam'),
  FPXBank(code: 'affin_bank', name: 'Affin Bank', shortName: 'Affin'),
  FPXBank(code: 'alliance_bank', name: 'Alliance Bank', shortName: 'Alliance'),
  FPXBank(code: 'bank_muamalat', name: 'Bank Muamalat', shortName: 'Muamalat'),
  FPXBank(code: 'bsn', name: 'BSN', shortName: 'BSN'),
  FPXBank(code: 'bank_rakyat', name: 'Bank Rakyat', shortName: 'Bank Rakyat'),
  FPXBank(code: 'ocbc', name: 'OCBC Bank', shortName: 'OCBC'),
  FPXBank(code: 'hsbc', name: 'HSBC Bank', shortName: 'HSBC'),
  FPXBank(code: 'standard_chartered', name: 'Standard Chartered', shortName: 'StanChart'),
  FPXBank(code: 'kfh', name: 'Kuwait Finance House', shortName: 'KFH'),
  FPXBank(code: 'uob', name: 'United Overseas Bank', shortName: 'UOB'),
  FPXBank(code: 'agrobank', name: 'Agrobank', shortName: 'Agrobank'),
];