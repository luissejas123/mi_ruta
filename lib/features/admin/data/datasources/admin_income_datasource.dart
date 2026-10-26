import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/core/utils/firestore_date.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_income_report.dart';

/// Lee los viajes cobrados y las recargas para el reporte de ingresos del
/// administrador (Obs. 8). Solo staff puede leer `recharges` ajenas
/// (`firestore.rules`), así que esta consulta es exclusiva del panel admin.
class AdminIncomeDatasource {
  final FirebaseFirestore _firestore;

  AdminIncomeDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Future<AdminIncomeReport> getIncome({
    required DateTime from,
    required DateTime to,
  }) async {
    final results = await Future.wait([
      _firestore
          .collection('trips')
          .where('payment_status', whereIn: ['paid', 'refunded'])
          .get(),
      _firestore
          .collection('recharges')
          .where('status', isEqualTo: 'approved')
          .get(),
    ]);

    final trips = results[0].docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        '_paid_date': parseFirestoreDate(data['paid_at']),
        '_refund_date': parseFirestoreDate(data['refunded_at']),
      };
    });
    final recharges = results[1].docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        '_date': parseFirestoreDate(data['verified_at'] ?? data['created_at']),
      };
    });

    return AdminIncomeReport.compute(
      trips: trips,
      recharges: recharges,
      from: from,
      to: to,
    );
  }
}
