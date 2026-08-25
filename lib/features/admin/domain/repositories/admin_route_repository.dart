import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

/// Repositorio de gestión administrativa de rutas.
///
/// Opera sobre las colecciones reales `routes` de Firestore y reutiliza el
/// parseo GTFS de assets para la carga de rutas.
abstract class AdminRouteRepository {
  /// Todas las rutas (activas e inactivas).
  Future<Either<Failure, List<RouteEntity>>> getRoutes();

  Future<Either<Failure, RouteEntity>> getRouteById(String routeId);

  /// Crea una ruta nueva en Firestore. Retorna su ID.
  Future<Either<Failure, String>> createRoute({
    required String name,
    required String ref,
    String? color,
    String? description,
    List<Map<String, double>>? stops,
    List<Map<String, double>>? polyline,
  });

  /// Actualiza metadatos de una ruta existente.
  Future<Either<Failure, void>> updateRoute({
    required String routeId,
    String? name,
    String? ref,
    String? color,
    String? description,
    bool? active,
  });

  /// Elimina (desactiva) una ruta.
  Future<Either<Failure, void>> deleteRoute(String routeId);

  /// Carga las rutas desde el GTFS bundleado en assets hacia Firestore.
  /// Retorna cuántas rutas se cargaron.
  Future<Either<Failure, int>> loadRoutesFromGtfs();
}
