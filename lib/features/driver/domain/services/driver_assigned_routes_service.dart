import 'package:mi_ruta/features/driver/data/datasources/driver_assigned_routes_datasource.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

class DriverAssignedRoutesService {
  final DriverAssignedRoutesDatasource _datasource;

  DriverAssignedRoutesService({
    required DriverAssignedRoutesDatasource datasource,
  }) : _datasource = datasource;

  Future<List<RouteEntity>> getAssignedRoutes(String driverId) =>
      _datasource.getAssignedRoutes(driverId);

  Future<void> saveAssignedRoute({
    required String driverId,
    required String routeId,
  }) => _datasource.saveAssignedRoute(driverId: driverId, routeId: routeId);
}
