import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/presidente/domain/entities/tariff_entity.dart';

abstract class TariffRepository {
  Future<Either<Failure, TariffEntity?>> getTariff(String routeRef);

  Future<Either<Failure, TariffEntity>> saveTariff({
    required String routeRef,
    required double pricePerKmBs,
  });
}
