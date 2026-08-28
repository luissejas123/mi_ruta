import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_ruta/features/user/domain/entities/benefit_request.dart';

class BenefitRequestDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BenefitRequestDatasource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  Future<void> _ensureAdministrator() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Sesión administrativa no válida');
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final role = (data['role'] ?? data['userType'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (role != 'admin' && role != 'administrador') {
      throw Exception('No tienes permisos para administrar beneficios');
    }
  }

  /// Crea una solicitud de beneficio con documentos
  Future<String> createBenefitRequest({
    required String userId,
    required String benefitType,
    required String description,
    required List<String> documentUrls,
  }) async {
    try {
      final existing = await getBenefitRequestsByUserId(userId);
      final duplicate = existing.any(
        (request) =>
            request.benefitType == benefitType &&
            (request.status == 'pending' || request.status == 'approved'),
      );
      if (duplicate) {
        throw Exception('Ya existe una solicitud activa para este beneficio');
      }

      final docRef = await _firestore.collection('benefit_requests').add({
        'user_id': userId,
        'benefit_type': benefitType,
        'status': 'pending',
        'document_urls': documentUrls,
        'description': description,
        'created_at': FieldValue.serverTimestamp(),
        'approved_at': null,
        'admin_notes': null,
      });

      // Crear transacción registrando la solicitud
      await _firestore.collection('transactions').add({
        'user_id': userId,
        'transaction_type': 'benefit_request',
        'amount': 0.0,
        'description': 'Solicitud de beneficio: $benefitType',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'benefit_request_id': docRef.id,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear solicitud de beneficio: $e');
    }
  }

  /// Obtiene una solicitud de beneficio por ID
  Future<BenefitRequest?> getBenefitRequestById(String requestId) async {
    try {
      final doc = await _firestore
          .collection('benefit_requests')
          .doc(requestId)
          .get();

      if (!doc.exists) return null;

      return _mapToBenefitRequest(doc);
    } catch (e) {
      throw Exception('Error al obtener solicitud de beneficio: $e');
    }
  }

  /// Obtiene el historial de solicitudes de beneficio del usuario
  Future<List<BenefitRequest>> getBenefitRequestsByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('benefit_requests')
          .where('user_id', isEqualTo: userId)
          .limit(50)
          .get();

      final requests = snapshot.docs.map(_mapToBenefitRequest).toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } catch (e) {
      throw Exception('Error al obtener solicitudes de beneficio: $e');
    }
  }

  Future<List<BenefitRequest>> getAllBenefitRequests() async {
    try {
      await _ensureAdministrator();
      final requestsSnapshot = await _firestore
          .collection('benefit_requests')
          .get();
      final usersSnapshot = await _firestore.collection('users').get();
      final users = <String, Map<String, dynamic>>{
        for (final doc in usersSnapshot.docs)
          (doc.data()['uid'] ?? doc.id).toString(): doc.data(),
      };

      final requests = requestsSnapshot.docs.map((doc) {
        final request = _mapToBenefitRequest(doc);
        final user = users[request.userId] ?? const <String, dynamic>{};
        return request.copyWith(
          userName: (user['full_name'] ?? user['fullName'])?.toString(),
          userEmail: user['email']?.toString(),
          userPhone: (user['phone_number'] ?? user['phoneNumber'])?.toString(),
          userType: (user['role'] ?? user['userType'])?.toString(),
        );
      }).toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } catch (e) {
      throw Exception('Error al obtener solicitudes administrativas: $e');
    }
  }

  /// Aprueba una solicitud de beneficio
  Future<void> approveBenefitRequest(
    String requestId,
    String adminNotes,
    String adminId,
  ) async {
    try {
      await _ensureAdministrator();
      final requestRef = _firestore
          .collection('benefit_requests')
          .doc(requestId);
      final request = await requestRef.get();
      if (!request.exists || request.data()?['status'] != 'pending') {
        throw Exception('La solicitud ya fue procesada');
      }
      final userId = request.data()?['user_id']?.toString();
      if (userId == null || userId.isEmpty) throw Exception('Usuario inválido');
      final batch = _firestore.batch();
      final transactions = await _firestore
          .collection('transactions')
          .where('benefit_request_id', isEqualTo: requestId)
          .get();
      batch.update(requestRef, {
        'status': 'approved',
        'approved_at': FieldValue.serverTimestamp(),
        'admin_notes': adminNotes,
        'decision_at': FieldValue.serverTimestamp(),
        'decision_by': adminId,
      });
      batch.set(_firestore.collection('users').doc(userId), {
        'active_benefits': FieldValue.arrayUnion([
          request.data()?['benefit_type'] ?? '',
        ]),
      }, SetOptions(merge: true));
      for (final transaction in transactions.docs) {
        batch.update(transaction.reference, {'status': 'approved'});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Error al aprobar solicitud: $e');
    }
  }

  /// Rechaza una solicitud de beneficio
  Future<void> rejectBenefitRequest(
    String requestId,
    String adminNotes,
    String adminId,
  ) async {
    try {
      await _ensureAdministrator();
      final requestRef = _firestore
          .collection('benefit_requests')
          .doc(requestId);
      final request = await requestRef.get();
      if (!request.exists || request.data()?['status'] != 'pending') {
        throw Exception('La solicitud ya fue procesada');
      }
      final batch = _firestore.batch();
      batch.update(requestRef, {
        'status': 'rejected',
        'admin_notes': adminNotes,
        'rejected_at': FieldValue.serverTimestamp(),
        'rejected_by': adminId,
        'decision_at': FieldValue.serverTimestamp(),
        'decision_by': adminId,
      });
      final transactions = await _firestore
          .collection('transactions')
          .where('benefit_request_id', isEqualTo: requestId)
          .get();
      for (final transaction in transactions.docs) {
        batch.update(transaction.reference, {'status': 'rejected'});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Error al rechazar solicitud: $e');
    }
  }

  BenefitRequest _mapToBenefitRequest(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BenefitRequest(
      id: doc.id,
      userId: data['user_id'] ?? '',
      benefitType: data['benefit_type'] ?? '',
      status: data['status'] ?? 'pending',
      documentUrls: List<String>.from(data['document_urls'] ?? []),
      description: data['description'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approved_at'] as Timestamp?)?.toDate(),
      adminNotes: data['admin_notes'],
      decisionAt: (data['decision_at'] as Timestamp?)?.toDate(),
      decisionBy: data['decision_by'],
      rejectedAt: (data['rejected_at'] as Timestamp?)?.toDate(),
      rejectedBy: data['rejected_by'],
    );
  }
}
