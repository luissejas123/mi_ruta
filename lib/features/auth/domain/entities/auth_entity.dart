import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable {
  final String uid;
  final String fullName;
  final String email;
  final String governmentId;
  final String phoneNumber;
  final String? profilePictureUrl;
  // Rol "activo" por defecto (pantalla de inicio tras login). Ver `roles`
  // para el conjunto completo de roles que tiene la cuenta — una cuenta
  // puede tener varios a la vez (ver RoleHierarchy).
  final String role;
  final DateTime createdAt;
  final Map<String, dynamic>? wallet;
  final Map<String, dynamic>? settings;
  // Acceso libre a los 5 perfiles para pruebas de QA — activado/desactivado
  // desde el panel de Admin (campo `qa_access` en users/{uid}).
  final bool qaAccess;
  // SuperAdmin: administrador con acceso total que ignora `admin_permissions`.
  // Vive solo en la base de datos (`users/{uid}.is_super_admin`), nunca en el
  // codigo. El primer superadmin se siembra a mano, ver SECURITY.md.
  final bool isSuperAdmin;
  // Todos los roles simultáneos que tiene la cuenta (siempre incluye
  // 'user'). Fuente de verdad para permisos — `role` es solo cuál de ellos
  // se usa como pantalla de inicio. Ver RoleHierarchy para las
  // combinaciones válidas.
  final List<String> roles;

  const AuthEntity({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.governmentId,
    required this.phoneNumber,
    this.profilePictureUrl,
    required this.role,
    required this.createdAt,
    this.wallet,
    this.settings,
    this.qaAccess = false,
    this.isSuperAdmin = false,
    this.roles = const ['user'],
  });

  @override
  List<Object?> get props => [
    uid,
    fullName,
    email,
    governmentId,
    phoneNumber,
    profilePictureUrl,
    role,
    createdAt,
    wallet,
    settings,
    qaAccess,
    isSuperAdmin,
    roles,
  ];
}
