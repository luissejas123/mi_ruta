import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';

abstract class VehicleRepository {
  Future<Either<Failure, VehicleEntity?>> getMyVehicle(String ownerUid);
  Stream<Either<Failure, VehicleEntity?>> getMyVehicleStream(String ownerUid);
  Future<Either<Failure, void>> setOnDuty(String vehicleId, bool value);
  Stream<Either<Failure, List<VehicleEntity>>> getActiveVehiclesStream();
}
