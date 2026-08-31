import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/admin/domain/entities/role_hierarchy.dart';
import 'package:mi_ruta/features/user/data/models/user_model.dart';

/// Acceso a Firestore para gestión de cuentas de cualquier rol (RQ-71/72).
/// Filtra en cliente sobre `userType` (ya resuelto por UserModel.fromJson
/// contra los dos campos legacy `role`/`userType`) para no perder cuentas
/// que solo tengan uno de los dos escritos.
class UserManagementDatasource {
  final FirebaseFirestore _firestore;

  UserManagementDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Asigna una ruta/línea (por `ref`) al PERFIL del chofer — no a la unidad.
  /// El chofer elige qué vehículo usar por su cuenta; DriverService.
  /// getAssignedRoute() prioriza este campo sobre vehicles.line_number.
  Future<void> assignRouteToDriver(String uid, String routeRef) async {
    await _firestore.collection('users').doc(uid).set({
      'assigned_route_ref': routeRef,
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<List<UserModel>> getUsers({String? userTypeFilter}) async {
    final snap = await _firestore.collection('users').get();
    final users = snap.docs.map((d) => UserModel.fromJson(d.data())).toList();
    if (userTypeFilter == null) return users;
    return users.where((u) => u.userType == userTypeFilter).toList();
  }

  Future<void> setUserActiveState(String uid, bool isActive) async {
    await _firestore.collection('users').doc(uid).set({
      'isActive': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// Activa/desactiva el acceso libre a los 5 perfiles para una cuenta de
  /// prueba — mecanismo QA, independiente de `is_super_admin`.
  Future<void> setQaAccess(String uid, bool qaAccess) async {
    await _firestore.collection('users').doc(uid).set({
      'qa_access': qaAccess,
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// Cuentas con una solicitud de chofer sin resolver. Se filtra en cliente por
  /// la misma razón que [getUsers]: los docs de `users` no son homogéneos.
  Future<List<UserModel>> getPendingDriverRequests() async {
    final snap = await _firestore.collection('users').get();
    return snap.docs
        .map((d) => UserModel.fromJson(d.data()))
        .where((u) => u.hasPendingDriverRequest)
        .toList();
  }

  /// El propio usuario pide ser chofer. **No toca `role`**: el rol solo cambia
  /// al aprobar, si no el ruteo lo mandaría a la pantalla de chofer antes de
  /// tiempo.
  Future<void> requestDriverRole(String uid) async {
    await _firestore.collection('users').doc(uid).set({
      'driver_request': {
        'status': 'pending',
        // ISO 8601: `users` usa strings, no Timestamp nativo.
        'requested_at': DateTime.now().toIso8601String(),
      },
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// Roles actuales de un doc de `users`, con fallback al esquema legado
  /// (un solo `role`/`userType`) para cuentas creadas antes de `roles`.
  Set<String> _rolesOf(Map<String, dynamic> data) {
    final raw = data['roles'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((r) => r.toString()).toSet();
    }
    final legacy = (data['role'] ?? data['userType']) as String? ?? RoleHierarchy.user;
    return {legacy};
  }

  /// Resuelve una solicitud. Al aprobar, el nuevo `roles`/`role` y el
  /// `driver_request.status` van en la **misma** escritura para que no pueda
  /// quedar un estado a medias (rol de chofer con solicitud aún pendiente).
  /// Otorga `driver` de forma aditiva — no le borra `user` (ni `presidente`
  /// si ya lo tuviera) a la cuenta.
  Future<void> resolveDriverRequest(String uid, {required bool approved}) async {
    final ref = _firestore.collection('users').doc(uid);
    final data = <String, dynamic>{
      'driver_request': {'status': approved ? 'approved' : 'rejected'},
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (approved) {
      final snap = await ref.get();
      final currentRoles = _rolesOf(snap.data() ?? {});
      if (!RoleHierarchy.canGrant(currentRoles, RoleHierarchy.driver)) {
        throw Exception(
          'No se puede aprobar como chofer: la cuenta ya tiene '
          '${currentRoles.join(", ")} y esa combinación no está permitida.',
        );
      }
      final newRoles = {...currentRoles, RoleHierarchy.user, RoleHierarchy.driver};
      data['roles'] = newRoles.toList();
      data['role'] = RoleHierarchy.primaryRole(newRoles);
    }
    await ref.set(data, SetOptions(merge: true));
  }

  /// Asigna el rol `tickeador` y su información de operación, de forma
  /// aditiva (no le borra `user` a la cuenta).
  ///
  /// La forma de `tickeador_info` es exactamente la que espera
  /// `TickeadorEntity.fromJson`: `assigned_station`, `assigned_lines`,
  /// `status`. Rol e info van en la misma escritura para que un tickeador
  /// nunca quede sin estación/líneas asignadas.
  Future<void> assignTickeador(
    String uid, {
    required String assignedStation,
    required List<String> assignedLines,
  }) async {
    final ref = _firestore.collection('users').doc(uid);
    final snap = await ref.get();
    final currentRoles = _rolesOf(snap.data() ?? {});
    if (!RoleHierarchy.canGrant(currentRoles, RoleHierarchy.tickeador)) {
      throw Exception(
        'No se puede asignar como tickeador: la cuenta ya tiene '
        '${currentRoles.join(", ")} y esa combinación no está permitida.',
      );
    }
    final newRoles = {...currentRoles, RoleHierarchy.user, RoleHierarchy.tickeador};
    await ref.set({
      'roles': newRoles.toList(),
      'role': RoleHierarchy.primaryRole(newRoles),
      'tickeador_info': {
        'assigned_station': assignedStation,
        'assigned_lines': assignedLines,
        'status': 'active',
      },
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
