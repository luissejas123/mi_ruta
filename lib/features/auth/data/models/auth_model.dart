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
    super.qaAccess,
    super.isSuperAdmin,
    super.roles,
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

    final legacyRole = (json['role'] ?? json['userType']) as String? ?? 'user';
    // `roles` es nuevo (Sprint 4): un doc que todavia no lo tiene solo
    // conoce su rol legado. No hace falta migrar los docs existentes.
    final rawRoles = json['roles'];
    final roles = rawRoles is List
        ? rawRoles.map((r) => r.toString()).toList()
        : <String>[legacyRole];

    return AuthModel(
      uid: json['uid'] as String? ?? '',
      // La colección users tiene docs snake_case y camelCase: leer ambas claves.
      fullName: (json['full_name'] ?? json['fullName']) as String? ?? '',
      email: json['email'] as String? ?? '',
      governmentId: (json['government_id'] ?? json['governmentId']) as String? ?? '',
      phoneNumber: (json['phone_number'] ?? json['phoneNumber']) as String? ?? '',
      profilePictureUrl: (json['profile_picture_url'] ?? json['profileImageUrl']) as String?,
      role: legacyRole,
      createdAt: parseCreatedAt(json['created_at'] ?? json['createdAt']),
      wallet: json['wallet'] as Map<String, dynamic>?,
      settings: json['settings'] as Map<String, dynamic>?,
      qaAccess: json['qa_access'] as bool? ?? false,
      isSuperAdmin: json['is_super_admin'] as bool? ?? false,
      roles: roles,
    );
  }

  Map<String, dynamic> toJson() {
    final defaultSettings = {
      'notifications_enabled': true,
      'trip_notifications_enabled': true,
      'recharge_notifications_enabled': true,
      'gift_notifications_enabled': true,
      'dark_mode_enabled': false,
      'is_driver_mode': false,
    };

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
      'settings': {...defaultSettings, ...(settings ?? {})},
    };
  }
}
