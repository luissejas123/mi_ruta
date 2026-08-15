import 'package:mi_ruta/features/driver/data/datasources/driver_datasource.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_trip_entity.dart';

/// Validación en ruta de cobros de viaje (RQ-78) e historial de
/// validaciones (RQ-79). Sin capa de datos propia: reusa DriverDatasource,
/// dueño de la colección `trips`, para no duplicar su mapeo de Firestore.
class TickeadorService {
  final DriverDatasource _driverDatasource;

  TickeadorService({required DriverDatasource driverDatasource})
      : _driverDatasource = driverDatasource;

  /// Escanea el mismo QR que usa el pasajero para pagar
  /// ("driverId|tripId|amount") y confirma que el viaje ya fue pagado.
  Future<DriverTripEntity> validatePayment(String qrData, String tickeadorUid) async {
    final parts = qrData.split('|');
    if (parts.length < 2) {
      throw Exception('Código QR inválido.');
    }
    final tripId = parts[1];

    final trip = await _driverDatasource.getTripById(tripId);
    if (trip == null) {
      throw Exception('No se encontró el viaje asociado a este código.');
    }
    if (!trip.isPaid) {
      throw Exception('Este viaje todavía no ha sido pagado.');
    }

    await _driverDatasource.markTripVerified(tripId, tickeadorUid);
    return await _driverDatasource.getTripById(tripId) ?? trip;
  }

  Future<List<DriverTripEntity>> getVerificationHistory(String tickeadorUid) =>
      _driverDatasource.getTripsVerifiedBy(tickeadorUid);
}
