import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/admin/domain/entities/transported_passengers_report.dart';
import 'package:mi_ruta/features/admin/domain/repositories/transported_passengers_repository.dart';

class GetTransportedPassengersUseCase {
  final TransportedPassengersRepository repository;

  GetTransportedPassengersUseCase(this.repository);

  Future<Either<Failure, TransportedPassengersReport>> call({
    required String routeRef,
    required DateTime from,
    required DateTime to,
  }) {
    return repository.getReport(routeRef: routeRef, from: from, to: to);
  }
}
