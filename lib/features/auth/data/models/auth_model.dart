import 'package:mi_ruta/features/auth/domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({
    required super.uid,
    required super.fullName,
    required super.email,
    required super.governmentId,
    required super.phoneNumber,
    super.profilePictureUrl,
    required super.role,
    required super.createdAt,
    super.wallet,
    super.settings,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    // Firestore puede devolver Timestamp o String para created_at
    DateTime parseCreatedAt(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      // Firestore Timestamp tiene .toDate()
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {}
      return DateTime.now();
    }

    return AuthModel(
      uid: json['uid'] as String? ?? '',
      // La colección users tiene docs snake_case y camelCase: leer ambas claves.
      fullName: (json['full_name'] ?? json['fullName']) as String? ?? '',
      email: json['email'] as String? ?? '',
      governmentId: (json['government_id'] ?? json['governmentId']) as String? ?? '',
      phoneNumber: (json['phone_number'] ?? json['phoneNumber']) as String? ?? '',
      profilePictureUrl: (json['profile_picture_url'] ?? json['profileImageUrl']) as String?,
      role: (json['role'] ?? json['userType']) as String? ?? 'user',
      createdAt: parseCreatedAt(json['created_at'] ?? json['createdAt']),
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
