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
  /// prueba (ver super_admin_config.dart) — usado por QA.
  Future<void> setQaAccess(String uid, bool qaAccess) async {
    await _firestore.collection('users').doc(uid).set({
      'qa_access': qaAccess,
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
