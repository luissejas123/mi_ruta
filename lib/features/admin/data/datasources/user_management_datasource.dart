import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/user/data/models/user_model.dart';

/// Acceso a Firestore para gestión de cuentas de cualquier rol (RQ-71/72).
/// Filtra en cliente sobre `userType` (ya resuelto por UserModel.fromJson
/// contra los dos campos legacy `role`/`userType`) para no perder cuentas
/// que solo tengan uno de los dos escritos.
class UserManagementDatasource {
  final FirebaseFirestore _firestore;

  UserManagementDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

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

  /// Resuelve una solicitud. Al aprobar, el cambio de `role` y el de
  /// `driver_request.status` van en la **misma** escritura para que no pueda
  /// quedar un estado a medias (rol de chofer con solicitud aún pendiente).
  Future<void> resolveDriverRequest(String uid, {required bool approved}) async {
    final data = <String, dynamic>{
      'driver_request': {'status': approved ? 'approved' : 'rejected'},
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (approved) {
      // Solo `role`, igual que AdminRemoteDataSourceImpl.updateUserRole: es la
      // clave que escribe todo el repo. Los lectores ya resuelven el legacy
      // `userType` con `role ?? userType` (ver UserModel.fromJson).
      data['role'] = 'driver';
    }
    await _firestore.collection('users').doc(uid).set(
          data,
          SetOptions(merge: true),
        );
  }

  /// Asigna el rol `tickeador` y su información de operación.
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
    await _firestore.collection('users').doc(uid).set({
      'role': 'tickeador',
      'tickeador_info': {
        'assigned_station': assignedStation,
        'assigned_lines': assignedLines,
        'status': 'active',
      },
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
