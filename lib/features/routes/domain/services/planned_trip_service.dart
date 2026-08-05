import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/routes/data/datasources/planned_trip_datasource.dart';
import 'package:mi_ruta/features/routes/domain/entities/planned_trip.dart';
import 'package:mi_ruta/features/routes/domain/services/multi_route_planner.dart';
import 'package:mi_ruta/features/routes/domain/services/route_data_sync_service.dart';
import 'package:mi_ruta/features/routes/domain/services/route_entity_converter.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';

class PlannedTripService {
  final PlannedTripDatasource _datasource;
  final RouteDataSyncService _syncService;

  PlannedTripService({
    required PlannedTripDatasource datasource,
    required RouteDataSyncService syncService,
  })  : _datasource = datasource,
        _syncService = syncService;

  Future<List<PlannedTrip>> searchOptions({
    required String userId,
    required LatLng origin,
    required LatLng destination,
    required String originName,
    required String destinationName,
  }) async {
    await _syncService.ensureDataReady();

    // Midpoint between origin and destination — needed for 3-leg combos
    final midLat = (origin.latitude + destination.latitude) / 2;
    final midLng = (origin.longitude + destination.longitude) / 2;
    final midpoint = LatLng(midLat, midLng);

    final results = await Future.wait([
      _syncService.getRoutesNearPoint(
          latitude: origin.latitude, longitude: origin.longitude),
      _syncService.getRoutesNearPoint(
          latitude: destination.latitude, longitude: destination.longitude),
      _syncService.getRoutesNearPoint(
          latitude: midpoint.latitude, longitude: midpoint.longitude),
    ]);

    final originRoutes = _toOsmRoutes(results[0]);
    final destRoutes = _toOsmRoutes(results[1]);
    final midRoutes = _toOsmRoutes(results[2]);

    if (originRoutes.isEmpty && destRoutes.isEmpty) return [];

    return MultiRoutePlanner.planAsync(
      userId: userId,
      origin: origin,
      destination: destination,
      originRoutes: originRoutes,
      destRoutes: destRoutes,
      midRoutes: midRoutes,
      originName: originName,
      destName: destinationName,
    );
  }

  Future<void> save(PlannedTrip trip) => _datasource.save(trip);

  Future<List<PlannedTrip>> getMyPlans(String userId) =>
      _datasource.getAll(userId);

  Future<void> markCompleted(String userId, String tripId) =>
      _datasource.markCompleted(userId, tripId);

  Future<void> delete(String userId, String tripId) =>
      _datasource.delete(userId, tripId);

  List<OsmRoute> _toOsmRoutes(List<dynamic> entities) {
    final routes = <OsmRoute>[];
    for (int i = 0; i < entities.length; i++) {
      routes.add(RouteEntityConverter.toOsmRoute(entities[i], i));
    }
    return routes;
  }
}
