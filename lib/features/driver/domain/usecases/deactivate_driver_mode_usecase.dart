import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/driver/domain/repositories/driver_repository.dart';

/// UseCase para volver al rol de pasajero. No requiere aprobación —
/// desactivar el modo chofer es una acción libre del usuario.
class DeactivateDriverModeUseCase {
  final DriverRepository repository;

  DeactivateDriverModeUseCase({required this.repository});

  Future<Either<Failure, void>> call(String userId) {
    return repository.deactivateDriverMode(userId);
  }
}
