import 'package:mi_ruta/features/admin/domain/entities/admin_user_entity.dart';

/// Modelo de datos del usuario administrado, normalizando las claves
/// `snake_case` y `camelCase` que coexisten en la colección `users`.
class AdminUserModel extends AdminUserEntity {
  const AdminUserModel({
    required super.uid,
    required super.fullName,
    required super.email,
    required super.phoneNumber,
    required super.role,
    super.settings,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      uid: json['uid'] as String? ?? '',
      fullName: (json['full_name'] ?? json['fullName']) as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber:
          (json['phone_number'] ?? json['phoneNumber']) as String? ?? '',
      role: (json['role'] ?? json['userType']) as String? ?? 'user',
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }
}
