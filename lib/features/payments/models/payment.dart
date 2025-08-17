enum PaymentStatus {
  pending,    // Payment intent created
  authorized, // Payment authorized but not captured
  completed,  // Payment captured
  failed;     // Payment failed

  String toJson() => name;
  
  static PaymentStatus fromString(String? value) {
    if (value == null) return PaymentStatus.pending;
    
    switch (value.toLowerCase()) {
      case 'authorized':
        return PaymentStatus.authorized;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }
}

class Payment {
  final String id;
  final String taskId;
  final String payerId;
  final String payeeId;
  final double amount;
  final PaymentStatus status;
  final String? stripePaymentIntentId;
  final String? clientSecret;
  final double? platformFeeAmount;
  final String? transferId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    String? id,
    required this.taskId,
    required this.payerId,
    required this.payeeId,
    required this.amount,
    PaymentStatus? status,
    this.stripePaymentIntentId,
    this.clientSecret,
    this.platformFeeAmount,
    this.transferId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? '',
    status = status ?? PaymentStatus.pending,
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      payerId: json['payer_id'] as String,
      payeeId: json['payee_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: PaymentStatus.fromString(json['status'] as String?),
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
      clientSecret: json['client_secret'] as String?,
      platformFeeAmount: json['platform_fee_amount'] != null 
          ? (json['platform_fee_amount'] as num).toDouble() 
          : null,
      transferId: json['transfer_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'payer_id': payerId,
      'payee_id': payeeId,
      'amount': amount,
      'status': status.toJson(),
      'stripe_payment_intent_id': stripePaymentIntentId,
      'client_secret': clientSecret,
      'platform_fee_amount': platformFeeAmount,
      'transfer_id': transferId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    String? taskId,
    String? payerId,
    String? payeeId,
    double? amount,
    PaymentStatus? status,
    String? stripePaymentIntentId,
    String? clientSecret,
    double? platformFeeAmount,
    String? transferId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      payerId: payerId ?? this.payerId,
      payeeId: payeeId ?? this.payeeId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      clientSecret: clientSecret ?? this.clientSecret,
      platformFeeAmount: platformFeeAmount ?? this.platformFeeAmount,
      transferId: transferId ?? this.transferId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 