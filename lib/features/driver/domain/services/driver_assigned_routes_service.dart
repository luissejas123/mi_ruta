import 'package:mi_ruta/features/driver/data/datasources/driver_assigned_routes_datasource.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

class DriverAssignedRoutesService {
  final DriverAssignedRoutesDatasource _datasource;

  DriverAssignedRoutesService({
    required DriverAssignedRoutesDatasource datasource,
  }) : _datasource = datasource;

  static List<RouteEntity> prioritizeActiveRoute({
    required List<RouteEntity> routes,
    required String? currentRouteIdOrRef,
  }) {
    if (currentRouteIdOrRef == null || currentRouteIdOrRef.isEmpty) {
      return routes;
    }

    final ordered = [...routes];
    ordered.sort((a, b) {
      final aIsCurrent = a.id == currentRouteIdOrRef || a.ref == currentRouteIdOrRef;
      final bIsCurrent = b.id == currentRouteIdOrRef || b.ref == currentRouteIdOrRef;
      if (aIsCurrent && !bIsCurrent) return -1;
      if (!aIsCurrent && bIsCurrent) return 1;
      return 0;
    });
    return ordered;
  }

  Future<List<RouteEntity>> getAssignedRoutes(String driverId) =>
      _datasource.getAssignedRoutes(driverId);

  Future<RouteEntity?> getCurrentAssignedRoute(
    String driverId, {
    String? fallbackLineNumber,
  }) =>
      _datasource.getCurrentAssignedRoute(
        driverId,
        fallbackLineNumber: fallbackLineNumber,
      );

  Future<void> saveAssignedRoute({
    required String driverId,
    required String routeId,
  }) => _datasource.saveAssignedRoute(driverId: driverId, routeId: routeId);
}
