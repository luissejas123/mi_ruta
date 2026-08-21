import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/user/domain/entities/benefit_request.dart';

class BenefitRequestDatasource {
  final FirebaseFirestore _firestore;

  BenefitRequestDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Crea una solicitud de beneficio con documentos
  Future<String> createBenefitRequest({
    required String userId,
    required String benefitType,
    required String description,
    required List<String> documentUrls,
  }) async {
    try {
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
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => _mapToBenefitRequest(doc)).toList();
    } catch (e) {
      throw Exception('Error al obtener solicitudes de beneficio: $e');
    }
  }

  /// Aprueba una solicitud de beneficio
  Future<void> approveBenefitRequest(
    String requestId,
    String adminNotes,
  ) async {
    try {
      await _firestore.collection('benefit_requests').doc(requestId).update({
        'status': 'approved',
        'approved_at': FieldValue.serverTimestamp(),
        'admin_notes': adminNotes,
      });
    } catch (e) {
      throw Exception('Error al aprobar solicitud: $e');
    }
  }

  /// Rechaza una solicitud de beneficio
  Future<void> rejectBenefitRequest(String requestId, String adminNotes) async {
    try {
      await _firestore.collection('benefit_requests').doc(requestId).update({
        'status': 'rejected',
        'admin_notes': adminNotes,
      });
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
    );
  }
}
