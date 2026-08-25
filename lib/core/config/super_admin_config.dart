/// Configuración del SuperAdmin.
///
/// El SuperAdmin es un administrador (role == "admin") con acceso total:
/// ignora `admin_permissions` y siempre tiene todos los privilegios.
class SuperAdminConfig {
  /// Correos con estatus de SuperAdmin (acceso total).
  ///
  /// SOLO DESARROLLO: admin@miruta.com es la cuenta de desarrollo creada por
  /// [DevAdminBootstrap]. En producción, reemplazar por correos reales.
  static const Set<String> superAdminEmails = {
    'admin@miruta.com',
  };
}
