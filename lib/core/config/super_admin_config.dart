/// Cuenta con acceso libre a los 5 perfiles (pasajero, chofer, dirigente,
/// administrador, tickeador) para pruebas de punta a punta del Sprint 3.
/// Ver `_AuthGate` en main.dart y `SuperAdminSwitcherPage`.
const kSuperAdminEmail = 'ohcame@gmail.com';

bool isSuperAdminEmail(String? email) =>
    email != null && email.toLowerCase() == kSuperAdminEmail.toLowerCase();
