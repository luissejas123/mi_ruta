import 'package:mi_ruta/features/auth/domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({
    required String uid,
    required String fullName,
    required String email,
    required String governmentId,
    required String phoneNumber,
    String? profilePictureUrl,
    required String role,
    required DateTime createdAt,
    Map<String, dynamic>? wallet,
    Map<String, dynamic>? settings,
  }) : super(
         uid: uid,
         fullName: fullName,
         email: email,
         governmentId: governmentId,
         phoneNumber: phoneNumber,
         profilePictureUrl: profilePictureUrl,
         role: role,
         createdAt: createdAt,
         wallet: wallet,
         settings: settings,
       );

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      uid: json['uid'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      governmentId: json['government_id'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      profilePictureUrl: json['profile_picture_url'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      wallet: json['wallet'] as Map<String, dynamic>?,
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'full_name': fullName,
      'email': email,
      'government_id': governmentId,
      'phone_number': phoneNumber,
      'profile_picture_url': profilePictureUrl,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'wallet': wallet ?? {'current_balance': 0.0, 'currency': 'Bs'},
      'settings':
          settings ?? {'dark_mode_enabled': false, 'is_driver_mode': false},
    };
  }
}
