import 'package:mi_ruta/features/driver/data/models/vehicle_model.dart';

/// Datasource remoto para la colección `vehicles` (ver
/// FIRESTORE_COLLECTIONS_GUIDE.md).
abstract class DriverDatasource {
  /// Crea (o sobrescribe) la solicitud de vehículo — doc id = placa.
  Future<void> createVehicleApplication(VehicleModel vehicle);

  /// Todas las solicitudes de vehículo del usuario (`owner_uid == userId`).
  Future<List<VehicleModel>> getVehicleApplicationsByOwner(String userId);
}
