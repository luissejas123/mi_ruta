import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_privileges.dart';

class AdminPrivilegesDatasource {
  final FirebaseFirestore _firestore;

  AdminPrivilegesDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Future<AdminPrivileges> getPrivileges(String adminId) async {
    final snapshot = await _firestore.collection('users').doc(adminId).get();
    final data = snapshot.data();
    final adminInfo = data?['admin_info'];
    final privileges = adminInfo is Map<String, dynamic>
        ? adminInfo['privileges']
        : null;
    return AdminPrivileges.fromMap(
      privileges is Map<String, dynamic> ? privileges : null,
    );
  }

  Future<void> savePrivileges(
    String adminId,
    AdminPrivileges privileges,
  ) async {
    await _firestore.collection('users').doc(adminId).set({
      'admin_info.privileges': privileges.toMap(),
    }, SetOptions(merge: true));
  }
}
