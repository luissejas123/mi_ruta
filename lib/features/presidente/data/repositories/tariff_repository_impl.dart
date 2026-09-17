import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/demo/demo_constants.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/presidente/domain/entities/tariff_entity.dart';
import 'package:mi_ruta/features/presidente/domain/repositories/tariff_repository.dart';

/// TODO(firestore): reemplazar por una impl real (colección
/// `tariffs/{route_ref}`) cuando exista acceso a Firestore. Por ahora vive
/// 100% en memoria, sembrada con una tarifa demo — se pierde al reiniciar
/// la app, es solo para probar el flujo de UI de RQ-121.
class InMemoryTariffRepository implements TariffRepository {
  final Map<String, TariffEntity> _tariffsByRouteRef = {
    kStaticDemoRouteRef: TariffEntity(
      routeRef: kStaticDemoRouteRef,
      pricePerKmBs: 0.5,
      updatedAt: DateTime.now(),
    ),
  };

  @override
  Future<Either<Failure, TariffEntity?>> getTariff(String routeRef) async {
    return Right(_tariffsByRouteRef[routeRef]);
  }

  @override
  Future<Either<Failure, TariffEntity>> saveTariff({
    required String routeRef,
    required double pricePerKmBs,
  }) async {
    final tariff = TariffEntity(
      routeRef: routeRef,
      pricePerKmBs: pricePerKmBs,
      updatedAt: DateTime.now(),
    );
    _tariffsByRouteRef[routeRef] = tariff;
    return Right(tariff);
  }
}
