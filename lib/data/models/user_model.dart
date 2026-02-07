import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// User model representing the authenticated user
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    String? displayName,
    String? avatarUrl,
    String? phoneNumber,
    DateTime? emailVerifiedAt,
    @Default(false) bool isOnboardingComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Create UserModel from Supabase auth user
  factory UserModel.fromSupabaseUser(dynamic user) {
    if (user == null) {
      throw ArgumentError('User cannot be null');
    }

    return UserModel(
      id: user.id as String,
      email: user.email as String? ?? '',
      displayName:
          user.userMetadata?['display_name'] as String? ??
          user.userMetadata?['full_name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
      phoneNumber: user.phone as String?,
      emailVerifiedAt: user.emailConfirmedAt != null
          ? DateTime.tryParse(user.emailConfirmedAt as String)
          : null,
      createdAt: user.createdAt != null
          ? DateTime.tryParse(user.createdAt as String)
          : null,
      updatedAt: user.updatedAt != null
          ? DateTime.tryParse(user.updatedAt as String)
          : null,
    );
  }
}
