import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/presidente/domain/entities/tariff_entity.dart';
import 'package:mi_ruta/features/presidente/domain/repositories/tariff_repository.dart';

class GetTariffUseCase {
  final TariffRepository repository;
  GetTariffUseCase({required this.repository});

  Future<Either<Failure, TariffEntity?>> call(String routeRef) =>
      repository.getTariff(routeRef);
}

class SaveTariffUseCase {
  final TariffRepository repository;
  SaveTariffUseCase({required this.repository});

  Future<Either<Failure, TariffEntity>> call({
    required String routeRef,
    required double pricePerKmBs,
  }) =>
      repository.saveTariff(routeRef: routeRef, pricePerKmBs: pricePerKmBs);
}
