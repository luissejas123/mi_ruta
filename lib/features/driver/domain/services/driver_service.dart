import 'package:mi_ruta/features/driver/data/datasources/driver_datasource.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

class DriverService {
  final DriverDatasource _datasource;

  DriverService({required DriverDatasource datasource}) : _datasource = datasource;

  Future<VehicleEntity?> getAssignedVehicle(String driverUid) {
    return _datasource.getVehicleForOwner(driverUid);
  }

  Future<VehicleEntity> startService(VehicleEntity vehicle) async {
    if (vehicle.lineNumber.trim().isEmpty) {
      throw Exception('El vehículo no tiene una línea asignada.');
    }
    await _datasource.startService(vehicle.vehicleId);
    return VehicleEntity(
      vehicleId: vehicle.vehicleId,
      ownerUid: vehicle.ownerUid,
      lineNumber: vehicle.lineNumber,
      inService: true,
      serviceStartedAt: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>> generateTripCharge({
    required VehicleEntity vehicle,
    required double amount,
    RouteEntity? route,
  }) async {
    if (amount <= 0) {
      throw Exception('El monto del cobro debe ser mayor a cero.');
    }
    if (vehicle.lineNumber.trim().isEmpty) {
      throw Exception('El vehículo no tiene una línea asignada.');
    }

    final tripId = await _datasource.createTripCharge(
      driverId: vehicle.ownerUid,
      vehicleId: vehicle.vehicleId,
      routeRef: vehicle.lineNumber,
      routeName: route?.name ?? vehicle.lineNumber,
      baseFare: amount,
    );
    return {
      'tripId': tripId,
      'qrData': '${vehicle.ownerUid}|$tripId|$amount',
      'amount': amount,
    };
  }
}