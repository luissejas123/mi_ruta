import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/user/domain/entities/recharge.dart';

class RecargeDatasource {
  final FirebaseFirestore _firestore;

  RecargeDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Crea una solicitud de recarga con comprobante
  Future<String> createRecharge({
    required String userId,
    required double amount,
    required String currency,
    required String proofImageUrl,
  }) async {
    try {
      final docRef = await _firestore.collection('recharges').add({
        'user_id': userId,
        'amount': amount,
        'currency': currency,
        'status': 'pending',
        'proof_image_url': proofImageUrl,
        'created_at': FieldValue.serverTimestamp(),
        'verified_at': null,
      });

      // También crear una transacción registrando la recarga
      await _firestore.collection('transactions').add({
        'user_id': userId,
        'transaction_type': 'recharge',
        'amount': amount,
        'description': 'Recarga con QR',
        'timestamp': FieldValue.serverTimestamp(),
        'payment_method': 'qr_proof',
        'status': 'pending',
        'recharge_id': docRef.id,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear recarga: $e');
    }
  }

  /// Obtiene una recarga por ID
  Future<Recharge?> getRechargeById(String rechargeId) async {
    try {
      final doc = await _firestore
          .collection('recharges')
          .doc(rechargeId)
          .get();

      if (!doc.exists) return null;

      return _mapToRecharge(doc);
    } catch (e) {
      throw Exception('Error al obtener recarga: $e');
    }
  }

  /// Obtiene el historial de recargas del usuario
  Future<List<Recharge>> getRechargesByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('recharges')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => _mapToRecharge(doc)).toList();
    } catch (e) {
      throw Exception('Error al obtener recargas: $e');
    }
  }

  /// Aprueba una recarga y añade el saldo a la billetera
  Future<void> approveRecharge(String rechargeId, String userId) async {
    try {
      final rechargeDoc = await _firestore
          .collection('recharges')
          .doc(rechargeId)
          .get();

      if (!rechargeDoc.exists) {
        throw Exception('Recarga no encontrada');
      }

      final amount = rechargeDoc['amount'] as double;

      // IMPORTANTE: Obtener el documento del usuario ANTES de la transacción
      // Firestore requiere todas las lecturas antes de las escrituras
      final userDocRef = _firestore.collection('users').doc(userId);
      final userSnapshot = await userDocRef.get();

      if (!userSnapshot.exists) {
        throw Exception('Usuario/Billetera no encontrada');
      }

      final currentBalance =
          (userSnapshot['wallet']['current_balance'] ?? 0.0) as double;

      // Obtener transacciones asociadas ANTES de la transacción
      final transactionQuery = await _firestore
          .collection('transactions')
          .where('recharge_id', isEqualTo: rechargeId)
          .limit(1)
          .get();

      // Ahora ejecutar la transacción con datos ya obtenidos
      await _firestore.runTransaction((transaction) async {
        // ACTUALIZAR: Recarga
        transaction.update(rechargeDoc.reference, {
          'status': 'approved',
          'verified_at': FieldValue.serverTimestamp(),
        });

        // ACTUALIZAR: Saldo del usuario
        transaction.update(userDocRef, {
          'wallet.current_balance': currentBalance + amount,
          'wallet.updated_at': FieldValue.serverTimestamp(),
        });

        // ACTUALIZAR: Transacción asociada
        if (transactionQuery.docs.isNotEmpty) {
          transaction.update(transactionQuery.docs.first.reference, {
            'status': 'approved',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Error al aprobar recarga: $e');
    }
  }

  /// Rechaza una recarga
  Future<void> rejectRecharge(String rechargeId, String reason) async {
    try {
      final rechargeDoc = await _firestore
          .collection('recharges')
          .doc(rechargeId)
          .get();

      if (!rechargeDoc.exists) {
        throw Exception('Recarga no encontrada');
      }

      // Obtener transacciones asociadas ANTES de la transacción
      final transactionQuery = await _firestore
          .collection('transactions')
          .where('recharge_id', isEqualTo: rechargeId)
          .limit(1)
          .get();

      await _firestore.runTransaction((transaction) async {
        // ACTUALIZAR: Recarga
        transaction.update(rechargeDoc.reference, {
          'status': 'rejected',
          'rejection_reason': reason,
          'verified_at': FieldValue.serverTimestamp(),
        });

        // ACTUALIZAR: Transacción asociada
        if (transactionQuery.docs.isNotEmpty) {
          transaction.update(transactionQuery.docs.first.reference, {
            'status': 'rejected',
          });
        }
      });
    } catch (e) {
      throw Exception('Error al rechazar recarga: $e');
    }
  }

  // Mapeo de documento Firestore a entidad Recharge
  Recharge _mapToRecharge(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Recharge(
      id: doc.id,
      userId: data['user_id'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'Bs',
      status: data['status'] ?? 'pending',
      proofImageUrl: data['proof_image_url'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verifiedAt: (data['verified_at'] as Timestamp?)?.toDate(),
    );
  }
}
