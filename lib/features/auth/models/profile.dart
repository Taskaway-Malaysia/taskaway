import 'package:freezed_annotation/freezed_annotation.dart';

// ignore_for_file: invalid_annotation_target

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Profile({
    required String id,
    String? username,
    required String fullName,
    required String role, 
    String? phone,
    String? avatarUrl,
    @Default(0.0) double rating,
    @Default(0) int totalTasks,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dateOfBirth,
    int? postcode,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}
