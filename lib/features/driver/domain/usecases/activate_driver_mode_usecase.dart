import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle.dart';
import 'package:mi_ruta/features/driver/domain/repositories/driver_repository.dart';

/// UseCase para activar el modo chofer. Solo permite la activación si la
/// solicitud de vehículo del usuario ya fue aprobada (`status == 'approved'`)
/// — esta es la regla de negocio central del feature, por eso vive aquí y no
/// en el repositorio.
class ActivateDriverModeUseCase {
  final DriverRepository repository;

  ActivateDriverModeUseCase({required this.repository});

  Future<Either<Failure, void>> call(String userId) async {
    final appResult = await repository.getMyVehicleApplication(userId);

    if (appResult is Left<Failure, Vehicle?>) {
      return Left(appResult.value);
    }

    final vehicle = (appResult as Right<Failure, Vehicle?>).value;
    if (vehicle == null || !vehicle.isApproved) {
      return Left(
        GeneralFailure(
          message: 'Tu solicitud de chofer aún no fue aprobada.',
        ),
      );
    }

    return repository.activateDriverMode(userId);
  }
}
