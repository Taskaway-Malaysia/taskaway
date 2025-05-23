class Payment {
  final String id;
  final String taskId;
  final String payerId;
  final String payeeId;
  final double amount;
  final String status;
  final String? billplzBillId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    String? id,
    required this.taskId,
    required this.payerId,
    required this.payeeId,
    required this.amount,
    String? status,
    this.billplzBillId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? '',
    status = status ?? 'pending',
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      payerId: json['payer_id'] as String,
      payeeId: json['payee_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      billplzBillId: json['billplz_bill_id'] as String?,
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
      'status': status,
      'billplz_bill_id': billplzBillId,
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
    String? status,
    String? billplzBillId,
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
      billplzBillId: billplzBillId ?? this.billplzBillId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 