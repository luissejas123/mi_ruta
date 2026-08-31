import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/admin/domain/repositories/admin_route_repository.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

class GetAdminRoutesUseCase {
  final AdminRouteRepository repository;

  GetAdminRoutesUseCase(this.repository);

  Future<Either<Failure, List<RouteEntity>>> call() async {
    return await repository.getRoutes();
  }
}

class GetAdminRouteByIdUseCase {
  final AdminRouteRepository repository;

  GetAdminRouteByIdUseCase(this.repository);

  Future<Either<Failure, RouteEntity>> call(String routeId) async {
    return await repository.getRouteById(routeId);
  }
}

class CreateAdminRouteUseCase {
  final AdminRouteRepository repository;

  CreateAdminRouteUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String name,
    required String ref,
    String? color,
    String? description,
    List<Map<String, double>>? stops,
    List<Map<String, double>>? polyline,
  }) async {
    return await repository.createRoute(
      name: name,
      ref: ref,
      color: color,
      description: description,
      stops: stops,
      polyline: polyline,
    );
  }
}

class UpdateAdminRouteUseCase {
  final AdminRouteRepository repository;

  UpdateAdminRouteUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String routeId,
    String? name,
    String? ref,
    String? color,
    String? description,
    bool? active,
  }) async {
    return await repository.updateRoute(
      routeId: routeId,
      name: name,
      ref: ref,
      color: color,
      description: description,
      active: active,
    );
  }
}

class DeleteAdminRouteUseCase {
  final AdminRouteRepository repository;

  DeleteAdminRouteUseCase(this.repository);

  Future<Either<Failure, void>> call(String routeId) async {
    return await repository.deleteRoute(routeId);
  }
}

class LoadRoutesFromGtfsUseCase {
  final AdminRouteRepository repository;

  LoadRoutesFromGtfsUseCase(this.repository);

  Future<Either<Failure, int>> call() async {
    return await repository.loadRoutesFromGtfs();
  }
}
