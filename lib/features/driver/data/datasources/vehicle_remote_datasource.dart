import 'package:mi_ruta/features/driver/data/models/vehicle_model.dart';

/// Contrato de acceso a datos de la colección `vehicles` en Firestore.
abstract class VehicleRemoteDataSource {
  /// Unidad asignada a [ownerUid] (el chofer es el dueño-operador). Null si no tiene ninguna.
  Future<VehicleModel?> getVehicleByOwnerUid(String ownerUid);

  /// Stream en tiempo real de la unidad asignada a [ownerUid].
  Stream<VehicleModel?> getVehicleByOwnerUidStream(String ownerUid);

  /// Marca la unidad [vehicleId] como en servicio o no.
  Future<void> setOnDuty(String vehicleId, bool value);

  /// Stream en tiempo real de todas las unidades actualmente en servicio.
  Stream<List<VehicleModel>> getActiveVehiclesStream();
}
