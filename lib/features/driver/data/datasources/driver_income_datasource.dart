import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_income_entry.dart';

class DriverIncomeDatasource {
  final FirebaseFirestore _firestore;

  DriverIncomeDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Ingresos recibidos por el chofer, generados por TripPaymentService.processPayment
  /// al pagar un viaje via QR (transactions.user_id == driverId).
  /// Requiere indice compuesto en Firestore: user_id + transaction_type + timestamp.
  Future<List<DriverIncomeEntry>> getIncomeHistory(String driverId) async {
    final snap = await _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: driverId)
        .where('transaction_type', isEqualTo: 'trip_payment_received')
        .orderBy('timestamp', descending: true)
        .get();

    return snap.docs.map((doc) {
      final d = doc.data();
      final timestamp = d['timestamp'];
      return DriverIncomeEntry(
        id: doc.id,
        driverId: d['user_id'] as String? ?? driverId,
        passengerId: d['passenger_id'] as String? ?? '',
        tripId: d['trip_id'] as String? ?? '',
        amount: (d['amount'] ?? 0).toDouble(),
        description: d['description'] as String? ?? 'Pago de viaje',
        date: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      );
    }).toList();
  }
}
