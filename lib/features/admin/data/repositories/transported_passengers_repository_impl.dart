import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/admin/data/datasources/transported_passengers_datasource.dart';
import 'package:mi_ruta/features/admin/domain/entities/transported_passengers_report.dart';
import 'package:mi_ruta/features/admin/domain/repositories/transported_passengers_repository.dart';

class TransportedPassengersRepositoryImpl
    implements TransportedPassengersRepository {
  final TransportedPassengersDatasource datasource;

  TransportedPassengersRepositoryImpl({required this.datasource});

  @override
  Future<Either<Failure, TransportedPassengersReport>> getReport({
    required String routeRef,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final result = await datasource.getReport(
        routeRef: routeRef,
        from: from,
        to: to,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
