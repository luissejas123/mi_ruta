import 'package:mi_ruta/features/driver/data/datasources/driver_datasource.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

class DriverService {
  final DriverDatasource _datasource;

  DriverService({required DriverDatasource datasource}) : _datasource = datasource;

  Future<VehicleEntity?> getAssignedVehicle(String driverUid) =>
      _datasource.getVehicleForOwner(driverUid);

  /// Inicia el servicio de la unidad asignada. Solo se permite si la
  /// unidad está aprobada por el dirigente/administración.
  Future<VehicleEntity> startService(VehicleEntity vehicle) async {
    if (vehicle.status != VehicleStatus.approved) {
      throw Exception(
        'La unidad ${vehicle.vehicleId} no está aprobada para operar '
        '(estado actual: ${_statusLabel(vehicle.status)}).',
      );
    }
    await _datasource.setVehicleServiceStatus(vehicle.vehicleId, true);
    return vehicle.copyWith(inService: true, serviceStartedAt: DateTime.now());
  }

  Future<VehicleEntity> stopService(VehicleEntity vehicle) async {
    await _datasource.setVehicleServiceStatus(vehicle.vehicleId, false);
    return vehicle.copyWith(inService: false, clearServiceStartedAt: true);
  }

  String _statusLabel(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.approved:
        return 'aprobada';
      case VehicleStatus.pendingReview:
        return 'en revisión';
      case VehicleStatus.rejected:
        return 'rechazada';
    }
  }

  /// Cuentas de chofer, para que el dirigente las apruebe o bloquee.
  Future<List<UserEntity>> getDriverUsers() => _datasource.getDriverUsers();

  Future<void> setDriverActive(String uid, bool isActive) =>
      _datasource.setUserActiveState(uid, isActive);
}
