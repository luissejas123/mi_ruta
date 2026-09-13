import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle.dart';
import 'package:mi_ruta/features/driver/domain/repositories/driver_repository.dart';

/// UseCase para enviar una solicitud de chofer (vehículo + documentos
/// legales). Valida los datos mínimos antes de delegar la subida y el
/// guardado al repositorio.
class SubmitVehicleApplicationUseCase {
  final DriverRepository repository;

  SubmitVehicleApplicationUseCase({required this.repository});

  Future<Either<Failure, Vehicle>> call({
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
    if (plate.trim().isEmpty) {
      return Left(
        GeneralFailure(message: 'La placa del vehículo es obligatoria.'),
      );
    }
    if (vehicleType.trim().isEmpty) {
      return Left(
        GeneralFailure(message: 'El tipo de vehículo es obligatorio.'),
      );
    }
    if (passengerCapacity <= 0) {
      return Left(
        GeneralFailure(
          message: 'La capacidad de pasajeros debe ser mayor a 0.',
        ),
      );
    }
    for (final file in [
      soatFile,
      vehicleInspectionFile,
      driverLicenseFile,
      municipalOperationCardFile,
      ruatFile,
    ]) {
      if (!file.existsSync()) {
        return Left(
          GeneralFailure(message: 'Uno o más documentos no existen.'),
        );
      }
    }

    return repository.submitVehicleApplication(
      userId: userId,
      plate: plate,
      vehicleType: vehicleType,
      lineNumber: lineNumber,
      internalNumber: internalNumber,
      brand: brand,
      model: model,
      color: color,
      passengerCapacity: passengerCapacity,
      soatFile: soatFile,
      vehicleInspectionFile: vehicleInspectionFile,
      driverLicenseFile: driverLicenseFile,
      municipalOperationCardFile: municipalOperationCardFile,
      ruatFile: ruatFile,
    );
  }
}
