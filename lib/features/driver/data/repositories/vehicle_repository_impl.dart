import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/driver/data/datasources/vehicle_remote_datasource.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/repositories/vehicle_repository.dart';

/// Implementación de VehicleRepository - Manejo de errores y delegación a DataSource.
class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleRemoteDataSource remoteDataSource;

  VehicleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, VehicleEntity?>> getMyVehicle(
      String ownerUid) async {
    try {
      final vehicle = await remoteDataSource.getVehicleByOwnerUid(ownerUid);
      return Right(vehicle);
    } on Exception {
      return Left(ServerFailure(message: 'Error obteniendo unidad asignada'));
    }
  }

  @override
  Stream<Either<Failure, VehicleEntity?>> getMyVehicleStream(
      String ownerUid) {
    return remoteDataSource
        .getVehicleByOwnerUidStream(ownerUid)
        .map((vehicle) => Right<Failure, VehicleEntity?>(vehicle))
        .handleError(
          (error) => Left<Failure, VehicleEntity?>(
            ServerFailure(message: 'Error en stream de unidad'),
          ),
        );
  }

  @override
  Future<Either<Failure, void>> setOnDuty(String vehicleId, bool value) async {
    try {
      await remoteDataSource.setOnDuty(vehicleId, value);
      return const Right(null);
    } on Exception {
      return Left(ServerFailure(message: 'Error actualizando estado de unidad'));
    }
  }

  @override
  Stream<Either<Failure, List<VehicleEntity>>> getActiveVehiclesStream() {
    return remoteDataSource
        .getActiveVehiclesStream()
        .map((vehicles) => Right<Failure, List<VehicleEntity>>(vehicles))
        .handleError(
          (error) => Left<Failure, List<VehicleEntity>>(
            ServerFailure(message: 'Error en stream de unidades activas'),
          ),
        );
  }
}
