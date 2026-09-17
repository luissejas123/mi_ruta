import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_shift.dart';
import 'package:mi_ruta/features/driver/domain/repositories/driver_shift_repository.dart';

/// TODO(firestore): reemplazar por una impl real (colección `driver_shifts`)
/// cuando exista acceso a Firestore. Por ahora vive 100% en memoria — se
/// pierde al reiniciar la app, es solo para probar el flujo de UI de RQ-82.
class InMemoryDriverShiftRepository implements DriverShiftRepository {
  final Map<String, DriverShiftEntity> _shiftsByVehicleId = {};
  int _nextId = 1;

  @override
  Future<Either<Failure, DriverShiftEntity>> startShift({
    required String vehicleId,
    required String driverUid,
  }) async {
    final shift = DriverShiftEntity(
      id: 'shift_${_nextId++}',
      vehicleId: vehicleId,
      driverUid: driverUid,
      startedAt: DateTime.now(),
      status: 'open',
    );
    _shiftsByVehicleId[vehicleId] = shift;
    return Right(shift);
  }

  @override
  Future<Either<Failure, DriverShiftEntity>> endShift({
    required String vehicleId,
  }) async {
    final open = _shiftsByVehicleId[vehicleId];
    if (open == null || !open.isOpen) {
      return Left(ServerFailure(message: 'No hay una jornada abierta.'));
    }
    final closed = open.copyWith(endedAt: DateTime.now(), status: 'closed');
    _shiftsByVehicleId[vehicleId] = closed;
    return Right(closed);
  }

  @override
  Future<Either<Failure, DriverShiftEntity?>> getOpenShift({
    required String vehicleId,
  }) async {
    final shift = _shiftsByVehicleId[vehicleId];
    return Right(shift != null && shift.isOpen ? shift : null);
  }
}
