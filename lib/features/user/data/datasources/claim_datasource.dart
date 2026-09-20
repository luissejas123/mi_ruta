import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_ruta/core/utils/firestore_date.dart';
import 'package:mi_ruta/features/user/domain/entities/claim_entity.dart';

/// Acceso a Firestore para `claims` (esquema documentado en
/// FIRESTORE_COLLECTIONS_GUIDE.md, colección ya protegida en
/// firestore.rules pero sin ningún lector/escritor hasta ahora).
///
/// A diferencia de `BenefitRequestDatasource` (su plantilla estructural),
/// TODOS los timestamps se escriben y se leen como `Timestamp` nativo — sin
/// mezclar con string ISO8601 — y solo hay un par resolución/autor
/// (`resolved_at`/`resolved_by`), no dos escrituras redundantes para el
/// mismo instante.
class ClaimDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ClaimDatasource({required FirebaseFirestore firestore, required FirebaseAuth auth})
      : _firestore = firestore,
        _auth = auth;

  Future<void> _ensureStaff() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Sesión no válida');
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final rawRoles = data['roles'];
    final roles = rawRoles is List
        ? rawRoles.map((r) => r.toString()).toSet()
        : {(data['role'] ?? data['userType'] ?? '').toString()};
    if (!roles.contains('admin') && !roles.contains('presidente')) {
      throw Exception('No tienes permisos para gestionar reclamos');
    }
  }

  /// Un pasajero (o chofer) crea un reclamo. `lineId` viene de quien reporta
  /// — no hay forma de derivarlo del reportante mismo (un pasajero no tiene
  /// línea propia), así que lo indica explícito en el formulario.
  Future<String> createClaim({
    required String reporterId,
    String? targetId,
    required String lineId,
    required String claimType,
    required String title,
    required String description,
  }) async {
    final docRef = await _firestore.collection('claims').add({
      'reporter_id': reporterId,
      'target_id': targetId,
      'line_id': lineId,
      'claim_type': claimType,
      'title': title,
      'description': description,
      'status': 'open',
      'created_at': FieldValue.serverTimestamp(),
      'resolved_at': null,
      'resolved_by': null,
      'resolution_note': null,
    });
    return docRef.id;
  }

  Future<List<ClaimEntity>> getClaimsByReporter(String reporterId) async {
    final snapshot = await _firestore
        .collection('claims')
        .where('reporter_id', isEqualTo: reporterId)
        .get();
    final claims = snapshot.docs.map(_mapToClaim).toList();
    claims.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return claims;
  }

  /// Reclamos visibles para el staff. [lineIds] no vacío (presidente con
  /// línea(s) asignada) filtra a esas líneas; vacío (admin, o presidente sin
  /// línea todavía) trae todos.
  Future<List<ClaimEntity>> getClaims({List<String> lineIds = const []}) async {
    await _ensureStaff();
    final snapshot = await _firestore.collection('claims').get();
    final usersSnapshot = await _firestore.collection('users').get();
    final users = <String, Map<String, dynamic>>{
      for (final doc in usersSnapshot.docs) (doc.data()['uid'] ?? doc.id).toString(): doc.data(),
    };

    String nameFor(String? uid) {
      if (uid == null || uid.isEmpty) return '';
      final u = users[uid];
      if (u == null) return '';
      return (u['full_name'] ?? u['fullName'] ?? '').toString();
    }

    var claims = snapshot.docs.map(_mapToClaim).map((c) {
      return c.copyWith(reporterName: nameFor(c.reporterId), targetName: nameFor(c.targetId));
    }).toList();

    if (lineIds.isNotEmpty) {
      claims = claims.where((c) => lineIds.contains(c.lineId)).toList();
    }
    claims.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return claims;
  }

  /// Resuelve un reclamo. `resolvedBy` es obligatorio (no negociable, ver
  /// Padre/Soberbia — 3 de los 4 mecanismos de "solicitud+resolución" que ya
  /// existían en el proyecto no registraban quién resolvió; este si).
  Future<void> resolveClaim(
    String claimId, {
    required String resolvedBy,
    String? resolutionNote,
  }) async {
    await _ensureStaff();
    final ref = _firestore.collection('claims').doc(claimId);
    final snap = await ref.get();
    if (!snap.exists || snap.data()?['status'] != 'open') {
      throw Exception('El reclamo ya fue resuelto o no existe');
    }
    await ref.update({
      'status': 'resolved',
      'resolved_at': FieldValue.serverTimestamp(),
      'resolved_by': resolvedBy,
      'resolution_note': resolutionNote,
    });
  }

  ClaimEntity _mapToClaim(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClaimEntity(
      id: doc.id,
      reporterId: (data['reporter_id'] ?? '').toString(),
      targetId: data['target_id']?.toString(),
      lineId: (data['line_id'] ?? '').toString(),
      claimType: (data['claim_type'] ?? 'service').toString(),
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      status: (data['status'] ?? 'open').toString(),
      createdAt: parseFirestoreDate(data['created_at']) ?? DateTime.now(),
      resolvedAt: parseFirestoreDate(data['resolved_at']),
      resolvedBy: data['resolved_by']?.toString(),
      resolutionNote: data['resolution_note']?.toString(),
    );
  }
}
