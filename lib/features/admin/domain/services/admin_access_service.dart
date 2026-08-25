import 'package:mi_ruta/core/config/super_admin_config.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_permissions.dart';
import 'package:mi_ruta/features/auth/domain/entities/auth_entity.dart';

/// Forma centralizada de consultar privilegios administrativos.
///
/// Reglas:
/// - El SuperAdmin siempre tiene acceso total (ignora `admin_permissions`).
/// - Un administrador normal depende de `settings.admin_permissions`.
/// - Un campo faltante nunca lanza excepción: devuelve false.
class AdminAccessService {
  AdminAccessService._();

  static bool isSuperAdmin(String email) {
    return SuperAdminConfig.superAdminEmails
        .contains(email.trim().toLowerCase());
  }

  static bool hasPermission(AuthEntity user, String permission) {
    if (isSuperAdmin(user.email)) return true;
    // Un usuario sin role "admin" nunca tiene privilegios administrativos.
    if (user.role != 'admin') return false;
    final perms = user.settings?['admin_permissions'];
    if (perms is Map) {
      return perms[permission] == true;
    }
    return false;
  }
}

/// Extensiones cómodas sobre AuthEntity para consultar permisos.
extension AuthAdminAccess on AuthEntity {
  bool get isSuperAdmin => AdminAccessService.isSuperAdmin(email);

  bool get canManageUsers =>
      AdminAccessService.hasPermission(this, AdminPermissions.manageUsers);

  bool get canManageAdmins =>
      AdminAccessService.hasPermission(this, AdminPermissions.manageAdmins);

  bool get canManagePermissions =>
      AdminAccessService.hasPermission(this, AdminPermissions.managePermissions);

  bool get canManageRoutes =>
      AdminAccessService.hasPermission(this, AdminPermissions.manageRoutes);
}
