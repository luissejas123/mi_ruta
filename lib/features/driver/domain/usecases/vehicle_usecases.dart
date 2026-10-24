import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/repositories/vehicle_repository.dart';

/// UseCase para obtener la unidad asignada al chofer
class GetMyVehicleUseCase {
  final VehicleRepository repository;
  GetMyVehicleUseCase({required this.repository});

  Future<Either<Failure, VehicleEntity?>> call(String ownerUid) async {
    return await repository.getMyVehicle(ownerUid);
  }
}

/// UseCase para stream en tiempo real de la unidad asignada al chofer
class GetMyVehicleStreamUseCase {
  final VehicleRepository repository;
  GetMyVehicleStreamUseCase({required this.repository});

  Stream<Either<Failure, VehicleEntity?>> call(String ownerUid) {
    return repository.getMyVehicleStream(ownerUid);
  }
}

/// UseCase para activar/desactivar el estado "en servicio" de una unidad
class SetVehicleOnDutyUseCase {
  final VehicleRepository repository;
  SetVehicleOnDutyUseCase({required this.repository});

  Future<Either<Failure, void>> call(String vehicleId, bool value) async {
    return await repository.setOnDuty(vehicleId, value);
  }
}

/// UseCase para stream en tiempo real de las unidades activas (uso admin)
class GetActiveVehiclesStreamUseCase {
  final VehicleRepository repository;
  GetActiveVehiclesStreamUseCase({required this.repository});

  Stream<Either<Failure, List<VehicleEntity>>> call() {
    return repository.getActiveVehiclesStream();
  }
}
