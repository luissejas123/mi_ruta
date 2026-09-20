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
    super.roles,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    final legacyRole = (json['role'] ?? json['userType']) as String? ?? 'user';
    final rawRoles = json['roles'];
    final roles = rawRoles is List
        ? rawRoles.map((r) => r.toString()).toList()
        : <String>[legacyRole];
    return AdminUserModel(
      uid: json['uid'] as String? ?? '',
      fullName: (json['full_name'] ?? json['fullName']) as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber:
          (json['phone_number'] ?? json['phoneNumber']) as String? ?? '',
      role: legacyRole,
      settings: json['settings'] as Map<String, dynamic>?,
      roles: roles,
    );
  }
}
