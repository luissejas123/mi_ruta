import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/admin/data/datasources/admin_route_datasource.dart';
import 'package:mi_ruta/features/admin/domain/repositories/admin_route_repository.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

class AdminRouteRepositoryImpl implements AdminRouteRepository {
  final AdminRouteDataSource remoteDataSource;

  AdminRouteRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<RouteEntity>>> getRoutes() async {
    try {
      final result = await remoteDataSource.getRoutes();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RouteEntity>> getRouteById(String routeId) async {
    try {
      final result = await remoteDataSource.getRouteById(routeId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createRoute({
    required String name,
    required String ref,
    String? color,
    String? description,
    List<Map<String, double>>? stops,
    List<Map<String, double>>? polyline,
  }) async {
    try {
      final result = await remoteDataSource.createRoute(
        name: name,
        ref: ref,
        color: color,
        description: description,
        stops: stops,
        polyline: polyline,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateRoute({
    required String routeId,
    String? name,
    String? ref,
    String? color,
    String? description,
    bool? active,
  }) async {
    try {
      await remoteDataSource.updateRoute(
        routeId: routeId,
        name: name,
        ref: ref,
        color: color,
        description: description,
        active: active,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRoute(String routeId) async {
    try {
      await remoteDataSource.deleteRoute(routeId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> loadRoutesFromGtfs() async {
    try {
      final result = await remoteDataSource.loadRoutesFromGtfs();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
