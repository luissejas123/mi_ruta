import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_shift.dart';

abstract class DriverShiftRepository {
  Future<Either<Failure, DriverShiftEntity>> startShift({
    required String vehicleId,
    required String driverUid,
  });

  Future<Either<Failure, DriverShiftEntity>> endShift({
    required String vehicleId,
  });

  Future<Either<Failure, DriverShiftEntity?>> getOpenShift({
    required String vehicleId,
  });
}
