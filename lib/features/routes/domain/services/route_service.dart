import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/routes/data/datasources/route_datasource.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

class RouteService {
  final RouteDatasource _datasource;

  RouteService({required RouteDatasource datasource})
    : _datasource = datasource;

  /// Obtiene todas las rutas activas
  Future<List<RouteEntity>> getAllActiveRoutes() {
    return _datasource.getAllActiveRoutes();
  }

  /// Obtiene N rutas activas (para búsqueda con paginación)
  Future<List<RouteEntity>> getActiveRoutesLimit(int limit) {
    return _datasource.getActiveRoutesLimit(limit);
  }

  /// Obtiene rutas con paginación real (usando offset/startAfter)
  /// Retorna un map con 'routes' y 'lastDoc' para continuar paginando
  /// Esto evita sobrecargar la respuesta de Firestore
  Future<Map<String, dynamic>> getActiveRoutesPaginated(
    int limit, {
    DocumentSnapshot? startAfter,
  }) {
    return _datasource.getActiveRoutesPaginated(limit, startAfter: startAfter);
  }

  /// Obtiene todas las rutas (incluyendo inactivas) - para admin
  Future<List<RouteEntity>> getAllRoutes() {
    return _datasource.getAllRoutes();
  }

  /// Obtiene una ruta por ID
  Future<RouteEntity?> getRouteById(String routeId) {
    return _datasource.getRouteById(routeId);
  }

  /// Obtiene una ruta por referencia (número de línea)
  Future<RouteEntity?> getRouteByRef(String ref) {
    return _datasource.getRouteByRef(ref);
  }

  /// Crea una nueva ruta
  Future<String> createRoute({
    required String name,
    required String ref,
    String? color,
    List<Map<String, double>>? stops,
    List<Map<String, double>>? polyline,
    String? description,
  }) {
    if (name.isEmpty || ref.isEmpty) {
      throw ArgumentError('Nombre y referencia son requeridos');
    }

    return _datasource.createRoute(
      name: name,
      ref: ref,
      color: color,
      stops: stops,
      polyline: polyline,
      description: description,
    );
  }

  /// Actualiza una ruta existente
  Future<void> updateRoute({
    required String routeId,
    String? name,
    String? ref,
    String? color,
    List<Map<String, double>>? stops,
    List<Map<String, double>>? polyline,
    String? description,
    bool? active,
  }) {
    return _datasource.updateRoute(
      routeId: routeId,
      name: name,
      ref: ref,
      color: color,
      stops: stops,
      polyline: polyline,
      description: description,
      active: active,
    );
  }

  /// Desactiva (elimina) una ruta
  Future<void> deleteRoute(String routeId) {
    return _datasource.deleteRoute(routeId);
  }
}
