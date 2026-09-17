import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_shift.dart';
import 'package:mi_ruta/features/driver/domain/repositories/driver_shift_repository.dart';

class StartDriverShiftUseCase {
  final DriverShiftRepository repository;
  StartDriverShiftUseCase({required this.repository});

  Future<Either<Failure, DriverShiftEntity>> call({
    required String vehicleId,
    required String driverUid,
  }) =>
      repository.startShift(vehicleId: vehicleId, driverUid: driverUid);
}

class EndDriverShiftUseCase {
  final DriverShiftRepository repository;
  EndDriverShiftUseCase({required this.repository});

  Future<Either<Failure, DriverShiftEntity>> call({
    required String vehicleId,
  }) =>
      repository.endShift(vehicleId: vehicleId);
}
