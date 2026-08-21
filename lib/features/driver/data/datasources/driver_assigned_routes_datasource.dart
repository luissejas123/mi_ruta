import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/routes/data/datasources/route_datasource.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

class DriverAssignedRoutesDatasource {
  final FirebaseFirestore _firestore;
  final RouteDatasource _routeDatasource;

  DriverAssignedRoutesDatasource({
    required FirebaseFirestore firestore,
    required RouteDatasource routeDatasource,
  }) : _firestore = firestore,
       _routeDatasource = routeDatasource;

  Future<List<RouteEntity>> getAssignedRoutes(String driverId) async {
    if (driverId.isEmpty) return [];

    final userDocument = await _firestore
        .collection('users')
        .doc(driverId)
        .get();
    final userData = userDocument.data();
    final driverProfile = userData?['driver_profile'];
    if (driverProfile is! Map<String, dynamic>) return [];

    final assignedRouteId = driverProfile['assigned_route_id'] as String?;
    if (assignedRouteId == null || assignedRouteId.isEmpty) return [];

    final routeById = await _routeDatasource.getRouteById(assignedRouteId);
    if (routeById != null) return [routeById];

    final routeReference = _routeReferenceFromAssignment(assignedRouteId);
    final routeByRef = await _routeDatasource.getRouteByRef(routeReference);
    return routeByRef == null ? [] : [routeByRef];
  }

  Future<void> saveAssignedRoute({
    required String driverId,
    required String routeId,
  }) async {
    await _firestore.collection('users').doc(driverId).update({
      'driver_profile.assigned_route_id': routeId,
    });
  }

  String _routeReferenceFromAssignment(String assignment) {
    final normalized = assignment.trim();
    final separatorIndex = normalized.lastIndexOf('_');
    if (separatorIndex == -1 || separatorIndex == normalized.length - 1) {
      return normalized;
    }
    return normalized.substring(separatorIndex + 1);
  }
}
