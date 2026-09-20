import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/admin/domain/entities/transported_passengers_report.dart';

abstract class TransportedPassengersRepository {
  /// Cuenta viajes/pasajeros transportados en una ruta dentro de [from]..[to]
  /// (inclusive), leyendo el historial de viajes de todos los pasajeros.
  Future<Either<Failure, TransportedPassengersReport>> getReport({
    required String routeRef,
    required DateTime from,
    required DateTime to,
  });
}
