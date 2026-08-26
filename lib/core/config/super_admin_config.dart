/// Cuenta con acceso libre a los 5 perfiles (pasajero, chofer, dirigente,
/// administrador, tickeador) para pruebas de punta a punta del Sprint 3.
/// Ver `_AuthGate` en main.dart y `SuperAdminSwitcherPage`.
const kSuperAdminEmail = 'ohcame@gmail.com';

bool isSuperAdminEmail(String? email) =>
    email != null && email.toLowerCase() == kSuperAdminEmail.toLowerCase();
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
