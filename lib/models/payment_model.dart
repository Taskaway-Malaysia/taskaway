import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_model.freezed.dart';
part 'payment_model.g.dart';

@freezed
class Payment with _$Payment {
  const factory Payment({
    required String id,
    required String taskId,
    required String payerId,
    required String payeeId,
    required double amount,
    required String billId,
    @Default('pending') String status,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
} 