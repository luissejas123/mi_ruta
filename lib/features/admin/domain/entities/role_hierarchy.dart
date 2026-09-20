/// Combinaciones de roles simultáneos permitidas en una cuenta.
///
/// Decisión de producto (Sprint 4, corrección sobre la jerarquía original):
/// toda cuenta es [user] (pasajero) por definición. Sobre esa base puede
/// tener como mucho un rol operativo exclusivo entre [admin], [driver] y
/// [tickeador] — nunca dos de esos tres a la vez. [presidente] es la
/// excepción: se puede otorgar sola (sobre `user`) o junto a [driver]
/// (un dirigente que también es chofer), pero nunca junto a [admin] ni
/// [tickeador].
///
/// Sin límite en la cantidad de cuentas que pueden tener `admin` o
/// `presidente` simultáneamente — es intencional para las pruebas de
/// Sprint 4; se le pondrá límite recién al cierre (ver
/// docs/SPRINT4_JERARQUIA_ROLES_PLAN.md).
class RoleHierarchy {
  RoleHierarchy._();

  static const String user = 'user';
  static const String admin = 'admin';
  static const String driver = 'driver';
  static const String tickeador = 'tickeador';
  static const String presidente = 'presidente';

  /// Único subconjunto de roles operativos (sin contar `user`, que siempre
  /// está) que una cuenta puede tener al mismo tiempo. Cualquier combinación
  /// que no esté acá se rechaza.
  static const List<Set<String>> _validExtraRoleSets = [
    {},
    {admin},
    {driver},
    {driver, presidente},
    {presidente},
    {tickeador},
  ];

  /// Orden de prioridad para decidir cuál es el rol "activo" por defecto
  /// (pantalla de inicio tras login) cuando una cuenta tiene varios. No
  /// limita a dónde puede entrar la cuenta — eso lo decide el selector de
  /// perfil (`RoleSwitcherPage`), que muestra todos los roles de [roles].
  static const List<String> _priority = [admin, presidente, driver, tickeador, user];

  /// true si [roles] es exactamente una de las combinaciones permitidas.
  static bool isValidRoleSet(Set<String> roles) {
    final extra = roles.where((r) => r != user).toSet();
    return _validExtraRoleSets.any(
      (valid) => valid.length == extra.length && valid.containsAll(extra),
    );
  }

  /// true si se le puede otorgar [newRole] a una cuenta que ya tiene
  /// [currentRoles], sin tener que quitarle ninguno de los roles actuales.
  static bool canGrant(Set<String> currentRoles, String newRole) {
    return isValidRoleSet({...currentRoles, user, newRole});
  }

  /// Rol "activo" por defecto entre todos los que tiene la cuenta — el que
  /// decide `homeScreenForRole` tras login. El resto sigue accesible desde
  /// el selector de perfil.
  static String primaryRole(Set<String> roles) {
    for (final r in _priority) {
      if (roles.contains(r)) return r;
    }
    return user;
  }

  static const Map<String, String> displayName = {
    user: 'Pasajero',
    admin: 'Administrador',
    driver: 'Chofer',
    tickeador: 'Tickeador',
    presidente: 'Presidente',
  };
}
