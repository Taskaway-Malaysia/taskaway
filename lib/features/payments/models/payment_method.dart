class PaymentMethod {
  final String id;
  final String userId;
  final PaymentMethodType type;
  final String? cardNumber; // Masked for display
  final String? cardHolderName;
  final String? expiryDate;
  final String? bankName;
  final String? eWalletProvider;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    this.cardNumber,
    this.cardHolderName,
    this.expiryDate,
    this.bankName,
    this.eWalletProvider,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: PaymentMethodType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PaymentMethodType.creditCard,
      ),
      cardNumber: json['card_number'] as String?,
      cardHolderName: json['card_holder_name'] as String?,
      expiryDate: json['expiry_date'] as String?,
      bankName: json['bank_name'] as String?,
      eWalletProvider: json['ewallet_provider'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'card_number': cardNumber,
      'card_holder_name': cardHolderName,
      'expiry_date': expiryDate,
      'bank_name': bankName,
      'ewallet_provider': eWalletProvider,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PaymentMethod copyWith({
    String? id,
    String? userId,
    PaymentMethodType? type,
    String? cardNumber,
    String? cardHolderName,
    String? expiryDate,
    String? bankName,
    String? eWalletProvider,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      expiryDate: expiryDate ?? this.expiryDate,
      bankName: bankName ?? this.bankName,
      eWalletProvider: eWalletProvider ?? this.eWalletProvider,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName {
    switch (type) {
      case PaymentMethodType.creditCard:
        return cardNumber ?? 'Credit Card';
      case PaymentMethodType.onlineBanking:
        return bankName ?? 'Online Banking';
      case PaymentMethodType.eWallet:
        return eWalletProvider ?? 'E-Wallet';
    }
  }

  String get maskedCardNumber {
    if (cardNumber == null) return '';
    if (cardNumber!.length < 4) return cardNumber!;
    return '**** **** **** ${cardNumber!.substring(cardNumber!.length - 4)}';
  }
}

enum PaymentMethodType {
  creditCard,
  onlineBanking,
  eWallet,
} 