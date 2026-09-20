import 'package:equatable/equatable.dart';

/// Usuario administrado desde el panel administrativo.
///
/// Proviene de la colección `users` de Firestore. Normaliza las claves
/// `snake_case` y `camelCase` que coexisten en esa colección.
class AdminUserEntity extends Equatable {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final Map<String, dynamic>? settings;
  // Todos los roles simultáneos de la cuenta (siempre incluye 'user'). Ver
  // RoleHierarchy para las combinaciones válidas.
  final List<String> roles;

  const AdminUserEntity({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.settings,
    this.roles = const ['user'],
  });

  bool get isAdmin => roles.contains('admin');

  /// Privilegios administrativos guardados en `settings.admin_permissions`.
  Map<String, dynamic> get adminPermissions {
    final perms = settings?['admin_permissions'];
    if (perms is Map) {
      return Map<String, dynamic>.from(perms);
    }
    return const {};
  }

  /// Permite saber si el usuario tiene un privilegio concreto.
  /// Un campo faltante nunca lanza excepción: devuelve false.
  bool hasPermission(String permission) {
    return adminPermissions[permission] == true;
  }

  @override
  List<Object?> get props => [
    uid,
    fullName,
    email,
    phoneNumber,
    role,
    settings,
    roles,
  ];
}
