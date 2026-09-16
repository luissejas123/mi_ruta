import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle.dart';
import 'package:mi_ruta/features/driver/domain/repositories/driver_repository.dart';

/// UseCase para obtener la solicitud de vehículo/chofer del usuario actual
/// (null si nunca solicitó convertirse en chofer).
class GetMyVehicleApplicationUseCase {
  final DriverRepository repository;

  GetMyVehicleApplicationUseCase({required this.repository});

  Future<Either<Failure, Vehicle?>> call(String userId) {
    return repository.getMyVehicleApplication(userId);
  }
}
