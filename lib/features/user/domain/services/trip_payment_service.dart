import 'package:cloud_firestore/cloud_firestore.dart';

class TripPaymentService {
  final FirebaseFirestore _firestore;

  TripPaymentService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Procesa el pago de un viaje escaneando el QR del chofer
  /// El QR contiene: driverId|tripId|amount
  Future<Map<String, dynamic>> processPayment({
    required String userId,
    required String qrData,
  }) async {
    try {
      // Decodificar QR: formato "driverId|tripId|amount"
      final parts = qrData.split('|');
      if (parts.length < 3) {
        throw Exception('Código QR inválido');
      }

      final String driverId = parts[0];
      final String tripId = parts[1];
      final double amount = double.parse(parts[2]);

      if (amount <= 0) {
        throw Exception('Monto inválido');
      }

      // Verificar que el viaje exista
      final tripDoc = await _firestore.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) {
        throw Exception('Viaje no encontrado');
      }

      final tripData = tripDoc.data() as Map<String, dynamic>;
      if (tripData['driver_id'] != driverId) {
        throw Exception('El chofer no coincide con el viaje');
      }

      // Obtener datos del usuario para verificar saldo
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final currentBalance = (userData['wallet_balance'] ?? 0).toDouble();

      if (currentBalance < amount) {
        throw Exception(
          'Saldo insuficiente. Saldo: Bs. ${currentBalance.toStringAsFixed(2)}, Requerido: Bs. ${amount.toStringAsFixed(2)}',
        );
      }

      // Realizar transacción atómica
      await _firestore.runTransaction((transaction) async {
        // Descontar de billetera del usuario
        transaction.update(_firestore.collection('users').doc(userId), {
          'wallet_balance': FieldValue.increment(-amount),
        });

        // Acreditar al chofer
        transaction.update(_firestore.collection('users').doc(driverId), {
          'wallet_balance': FieldValue.increment(amount),
        });

        // Actualizar estado del viaje
        transaction.update(_firestore.collection('trips').doc(tripId), {
          'status': 'completed',
          'passenger_id': userId,
          'payment_status': 'paid',
          'payment_amount': amount,
          'paid_at': FieldValue.serverTimestamp(),
        });
      });

      // Registrar transacción para el usuario
      await _firestore.collection('transactions').add({
        'user_id': userId,
        'transaction_type': 'trip_payment',
        'amount': -amount,
        'description': 'Pago de viaje con chofer $driverId',
        'timestamp': FieldValue.serverTimestamp(),
        'payment_method': 'qr',
        'status': 'completed',
        'trip_id': tripId,
        'driver_id': driverId,
      });

      // Registrar transacción para el chofer
      await _firestore.collection('transactions').add({
        'user_id': driverId,
        'transaction_type': 'trip_payment_received',
        'amount': amount,
        'description': 'Pago de viaje del pasajero $userId',
        'timestamp': FieldValue.serverTimestamp(),
        'payment_method': 'qr',
        'status': 'completed',
        'trip_id': tripId,
        'passenger_id': userId,
      });

      return {
        'success': true,
        'amount': amount,
        'driverId': driverId,
        'tripId': tripId,
        'newBalance': currentBalance - amount,
        'message':
            'Pago procesado exitosamente. Saldo: Bs. ${(currentBalance - amount).toStringAsFixed(2)}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error al procesar pago: $e'};
    }
  }

  /// Obtiene el historial de pagos de viajes del usuario
  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          .where('transaction_type', isEqualTo: 'trip_payment')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error al obtener historial de pagos: $e');
    }
  }

  /// Verifica si un viaje ya fue pagado
  Future<bool> isTripPaid(String tripId) async {
    try {
      final tripDoc = await _firestore.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) return false;

      final tripData = tripDoc.data() as Map<String, dynamic>;
      return tripData['payment_status'] == 'paid';
    } catch (e) {
      throw Exception('Error al verificar estado del pago: $e');
    }
  }
}
