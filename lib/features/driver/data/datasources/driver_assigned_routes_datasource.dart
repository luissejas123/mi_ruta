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
    final allRoutes = await _routeDatasource.getAllActiveRoutes();
    if (allRoutes.isEmpty) return const [];

    final assignedIdOrRef = await _getAssignedRouteIdOrRef(driverId);
    if (assignedIdOrRef == null || assignedIdOrRef.isEmpty) {
      return allRoutes;
    }

    final prioritized = [...allRoutes];
    prioritized.sort((a, b) {
      final aIsAssigned = a.id == assignedIdOrRef || a.ref == assignedIdOrRef;
      final bIsAssigned = b.id == assignedIdOrRef || b.ref == assignedIdOrRef;
      if (aIsAssigned && !bIsAssigned) return -1;
      if (!aIsAssigned && bIsAssigned) return 1;
      return 0;
    });
    return prioritized;
  }

  Future<RouteEntity?> getCurrentAssignedRoute(
    String driverId, {
    String? fallbackLineNumber,
  }) async {
    if (driverId.isEmpty) return null;

    final assignedRefOrId = await _getAssignedRouteIdOrRef(driverId);
    if (assignedRefOrId != null && assignedRefOrId.isNotEmpty) {
      final routeById = await _routeDatasource.getRouteById(assignedRefOrId);
      if (routeById != null) return routeById;
      final routeByRef = await _routeDatasource.getRouteByRef(
        _routeReferenceFromAssignment(assignedRefOrId),
      );
      if (routeByRef != null) return routeByRef;
    }

    final lineNumber = fallbackLineNumber ?? await _getDriverLineNumber(driverId);
    if (lineNumber == null || lineNumber.isEmpty) return null;
    return _routeDatasource.getRouteByRef(lineNumber);
  }

  Future<void> saveAssignedRoute({
    required String driverId,
    required String routeId,
  }) async {
    await _firestore.collection('users').doc(driverId).update({
      'driver_profile.assigned_route_id': routeId,
    });
  }

  Future<String?> _getAssignedRouteIdOrRef(String driverId) async {
    final userDoc = await _firestore.collection('users').doc(driverId).get();
    final userData = userDoc.data();
    final driverProfile = userData?['driver_profile'];
    if (driverProfile is! Map<String, dynamic>) return null;

    final assignedRoute = driverProfile['assigned_route_id'];
    if (assignedRoute is! String || assignedRoute.isEmpty) return null;
    return assignedRoute;
  }

  Future<String?> _getDriverLineNumber(String driverId) async {
    final vehicleSnapshot = await _firestore
        .collection('vehicles')
        .where('owner_uid', isEqualTo: driverId)
        .limit(1)
        .get();

    if (vehicleSnapshot.docs.isEmpty) return null;
    final data = vehicleSnapshot.docs.first.data();
    final lineNumber = data['line_number'] as String?;
    return lineNumber == null || lineNumber.isEmpty ? null : lineNumber;
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
