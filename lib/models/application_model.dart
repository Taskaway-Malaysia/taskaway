import 'package:freezed_annotation/freezed_annotation.dart';

part 'application_model.freezed.dart';
part 'application_model.g.dart';

@freezed
class Application with _$Application {
  const factory Application({
    required String id,
    required String taskId,
    required String taskerId,
    required String coverLetter,
    required double proposedPrice,
    @Default('pending') String status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Application;

  factory Application.fromJson(Map<String, dynamic> json) => _$ApplicationFromJson(json);
} 