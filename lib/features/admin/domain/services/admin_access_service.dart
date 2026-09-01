import 'package:mi_ruta/features/admin/domain/entities/admin_permissions.dart';
import 'package:mi_ruta/features/auth/domain/entities/auth_entity.dart';

/// Forma centralizada de consultar privilegios administrativos.
///
/// Reglas:
/// - El SuperAdmin siempre tiene acceso total (ignora `admin_permissions`).
/// - Un administrador normal depende de `settings.admin_permissions`.
/// - Un campo faltante nunca lanza excepción: devuelve false.
///
/// La condición de SuperAdmin vive únicamente en la base de datos
/// (`users/{uid}.is_super_admin`), nunca en una lista de correos en el código.
/// Cómo se siembra el primer superadmin: ver SECURITY.md.
class AdminAccessService {
  AdminAccessService._();

  static bool isSuperAdmin(AuthEntity user) => user.isSuperAdmin;

  static bool hasPermission(AuthEntity user, String permission) {
    if (isSuperAdmin(user)) return true;
    // Un usuario sin role "admin" nunca tiene privilegios administrativos.
    if (user.role != 'admin') return false;
    final perms = user.settings?['admin_permissions'];
    if (perms is Map) {
      return perms[permission] == true;
    }
    return false;
  }

  static bool canAccessOperation(AuthEntity user, AdminOperation operation) =>
      hasPermission(user, operation.permissionKey);

  static List<AdminOperation> getAvailableOperations(AuthEntity user) {
    if (isSuperAdmin(user)) {
      return AdminOperation.values;
    }
    if (user.role != 'admin') {
      return const [];
    }

    return AdminOperation.values
        .where((operation) => hasPermission(user, operation.permissionKey))
        .toList();
  }

  /// Responsabilidades fijas del rol `presidente`. No se mezclan con el esquema
  /// configurable de `admin_permissions`, que aplica solo al rol `admin`.
  static bool canApproveChoferRequests(AuthEntity user) =>
      isSuperAdmin(user) || user.role == 'presidente' || user.role == 'admin';

  static bool canAssignTickeador(AuthEntity user) =>
      isSuperAdmin(user) || user.role == 'presidente' || user.role == 'admin';
}

/// Extensiones cómodas sobre AuthEntity para consultar permisos.
extension AuthAdminAccess on AuthEntity {
  bool get canManageUsers =>
      AdminAccessService.hasPermission(this, AdminPermissions.manageUsers);

  bool get canManageAdmins =>
      AdminAccessService.hasPermission(this, AdminPermissions.manageAdmins);

  bool get canManagePermissions =>
      AdminAccessService.hasPermission(this, AdminPermissions.managePermissions);

  bool get canManageRoutes =>
      AdminAccessService.hasPermission(this, AdminPermissions.manageRoutes);

  bool get canApproveChoferRequests =>
      AdminAccessService.canApproveChoferRequests(this);

  bool get canAssignTickeador => AdminAccessService.canAssignTickeador(this);
}
