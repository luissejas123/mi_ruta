import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/driver/data/datasources/driver_datasource.dart';
import 'package:mi_ruta/features/driver/data/models/vehicle_model.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_legal_documents.dart';
import 'package:mi_ruta/features/driver/domain/repositories/driver_repository.dart';
import 'package:mi_ruta/features/user/domain/services/storage_service.dart';
import 'package:mi_ruta/features/user/domain/usecases/user_usecases.dart';

class DriverRepositoryImpl implements DriverRepository {
  final DriverDatasource _datasource;
  final StorageService _storageService;
  final UpdateUserUseCase _updateUserUseCase;

  DriverRepositoryImpl({
    required DriverDatasource datasource,
    required StorageService storageService,
    required UpdateUserUseCase updateUserUseCase,
  })  : _datasource = datasource,
        _storageService = storageService,
        _updateUserUseCase = updateUserUseCase;

  @override
  Future<Either<Failure, Vehicle>> submitVehicleApplication({
    required String userId,
    required String plate,
    required String vehicleType,
    required String lineNumber,
    required String internalNumber,
    required String brand,
    required String model,
    required String color,
    required int passengerCapacity,
    required File soatFile,
    required File vehicleInspectionFile,
    required File driverLicenseFile,
    required File municipalOperationCardFile,
    required File ruatFile,
  }) async {
    // TODO: si una subida falla a mitad de las 5 (p. ej. la 3ra tira
    // excepción), los documentos ya subidos con éxito (1ra y 2da) quedan
    // huérfanos en Storage — no se revierten ni se limpian. Aceptable por
    // ahora (fuera de alcance de RQ-68), pero a considerar si esto necesita
    // un mecanismo de limpieza/rollback más adelante.
    try {
      final soatUrl = await _storageService.uploadVehicleDocument(
        plate: plate,
        documentType: 'soat',
        documentFile: soatFile,
      );
      final inspectionUrl = await _storageService.uploadVehicleDocument(
        plate: plate,
        documentType: 'vehicle_inspection',
        documentFile: vehicleInspectionFile,
      );
      final licenseUrl = await _storageService.uploadVehicleDocument(
        plate: plate,
        documentType: 'driver_license',
        documentFile: driverLicenseFile,
      );
      final municipalUrl = await _storageService.uploadVehicleDocument(
        plate: plate,
        documentType: 'municipal_operation_card',
        documentFile: municipalOperationCardFile,
      );
      final ruatUrl = await _storageService.uploadVehicleDocument(
        plate: plate,
        documentType: 'ruat',
        documentFile: ruatFile,
      );

      final vehicle = VehicleModel.newApplication(
        plate: plate,
        ownerUid: userId,
        vehicleType: vehicleType,
        lineNumber: lineNumber,
        internalNumber: internalNumber,
        brand: brand,
        model: model,
        color: color,
        passengerCapacity: passengerCapacity,
        legalDocuments: VehicleLegalDocuments(
          soatUrl: soatUrl,
          vehicleInspectionUrl: inspectionUrl,
          driverLicenseUrl: licenseUrl,
          municipalOperationCardUrl: municipalUrl,
          ruatUrl: ruatUrl,
        ),
      );

      await _datasource.createVehicleApplication(vehicle);
      return Right(vehicle);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Error al enviar la solicitud de chofer: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, Vehicle?>> getMyVehicleApplication(
    String userId,
  ) async {
    try {
      final vehicles = await _datasource.getVehicleApplicationsByOwner(
        userId,
      );
      return Right(vehicles.isEmpty ? null : vehicles.first);
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'Error al obtener tu solicitud de chofer: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> activateDriverMode(String userId) {
    // NOTA: se escribe solo 'role' (no 'userType') porque es el campo
    // autoritativo real — UserModel.fromJson lo prioriza y UserModel.toJson()
    // solo reescribe 'role' en cualquier actualización de perfil. 'userType'
    // se sincroniza únicamente en el registro
    // (auth_remote_datasource_impl.dart) y queda huérfano después.
    // TODO: evaluar si conviene eliminar/migrar 'userType' — fuera de
    // alcance de RQ-68.
    return _updateUserUseCase(userId, {
      'role': 'driver',
      'settings.is_driver_mode': true,
    });
  }

  @override
  Future<Either<Failure, void>> deactivateDriverMode(String userId) {
    return _updateUserUseCase(userId, {
      'role': 'user',
      'settings.is_driver_mode': false,
    });
  }
}
