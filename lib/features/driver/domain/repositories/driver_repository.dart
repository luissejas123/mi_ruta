import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle.dart';

/// Contrato de acceso a datos del feature Chofer.
/// Retorna `Either<Failure, Data>` para manejo de errores (ver CLAUDE.md).
abstract class DriverRepository {
  /// Sube los 5 documentos legales a Storage y crea la solicitud de
  /// vehículo en Firestore con status inicial 'pending_review'.
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
  });

  /// Última solicitud de vehículo del usuario, o null si nunca solicitó.
  Future<Either<Failure, Vehicle?>> getMyVehicleApplication(String userId);

  /// Persiste el cambio de rol a chofer, reutilizando el esquema existente
  /// de `users` (`role` / `settings.is_driver_mode`). La regla de negocio
  /// "solo si la solicitud está aprobada" vive en el usecase, no aquí.
  Future<Either<Failure, void>> activateDriverMode(String userId);

  /// Vuelve al rol de pasajero.
  Future<Either<Failure, void>> deactivateDriverMode(String userId);
}
