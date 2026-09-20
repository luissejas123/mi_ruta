import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

abstract class AdminRouteDataSource {
  Future<List<RouteEntity>> getRoutes();

  Future<RouteEntity> getRouteById(String routeId);

  Future<String> createRoute({
    required String name,
    required String ref,
    String? color,
    String? description,
    List<Map<String, double>>? stops,
    List<Map<String, double>>? polyline,
  });

  Future<void> updateRoute({
    required String routeId,
    String? name,
    String? ref,
    String? color,
    String? description,
    bool? active,
  });

  Future<void> deleteRoute(String routeId);

  /// Carga rutas desde el GTFS de assets hacia Firestore.
  Future<int> loadRoutesFromGtfs();
}
