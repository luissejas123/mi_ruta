/// Claves de privilegios administrativos.
///
/// Solo se definen permisos que corresponden a módulos administrativos
/// realmente implementados en la app.
class AdminPermissions {
  AdminPermissions._();

  /// Gestión de usuarios (listar, buscar, ver detalles).
  static const String manageUsers = 'manage_users';

  /// Promover/revocar administradores.
  static const String manageAdmins = 'manage_admins';

  /// Gestión de privilegios de administradores.
  static const String managePermissions = 'manage_permissions';

  /// Gestión de rutas (cargar, editar, eliminar).
  static const String manageRoutes = 'manage_routes';

  /// Todos los privilegios existentes.
  static const List<String> all = [
    manageUsers,
    manageAdmins,
    managePermissions,
    manageRoutes,
  ];
}

enum AdminOperation {
  manageUsers,
  manageAdmins,
  managePermissions,
  manageRoutes,
}

extension AdminOperationX on AdminOperation {
  String get permissionKey {
    switch (this) {
      case AdminOperation.manageUsers:
        return AdminPermissions.manageUsers;
      case AdminOperation.manageAdmins:
        return AdminPermissions.manageAdmins;
      case AdminOperation.managePermissions:
        return AdminPermissions.managePermissions;
      case AdminOperation.manageRoutes:
        return AdminPermissions.manageRoutes;
    }
  }
}
