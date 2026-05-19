import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/utils/distance_utils.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';

/// Conversor y filtros de [RouteEntity] para uso en búsqueda de rutas.
class RouteEntityConverter {
  RouteEntityConverter._();

  /// Devuelve `true` si algún punto de [entity] está dentro de [maxDist]
  /// metros de [origin] o [destination].
  static bool hasPointNearTargets(
    RouteEntity entity,
    LatLng origin,
    LatLng destination,
    double maxDist,
  ) {
    final allCoords = [...(entity.stops ?? []), ...(entity.polyline ?? [])];
    if (allCoords.isEmpty) return false;
    final step = allCoords.length > 20 ? 5 : 1;
    for (int j = 0; j < allCoords.length; j += step) {
      final lat = allCoords[j]['lat'];
      final lng = allCoords[j]['lng'];
      if (lat == null || lng == null) continue;
      final point = LatLng(lat, lng);
      if (DistanceUtils.metersApprox(origin, point) < maxDist ||
          DistanceUtils.metersApprox(destination, point) < maxDist) {
        return true;
      }
    }
    return false;
  }

  /// Convierte un [RouteEntity] a [OsmRoute] para uso en [RouteFinderService].
  static OsmRoute toOsmRoute(RouteEntity entity, int index) {
    final segments = <List<LatLng>>[];
    if (entity.polyline != null && entity.polyline!.isNotEmpty) {
      final segment = entity.polyline!
          .map((c) => LatLng(c['lat'] ?? 0.0, c['lng'] ?? 0.0))
          .toList();
      if (segment.isNotEmpty) segments.add(segment);
    } else if (entity.stops != null && entity.stops!.isNotEmpty) {
      final segment = entity.stops!
          .map((s) => LatLng(s['lat'] ?? 0.0, s['lng'] ?? 0.0))
          .toList();
      if (segment.isNotEmpty) segments.add(segment);
    }
    return OsmRoute(
      id: index,
      name: entity.name,
      ref: entity.ref,
      segments: segments.isEmpty
          ? [
              [
                const LatLng(-17.391032, -66.1568),
                const LatLng(-17.395, -66.160),
              ],
            ]
          : segments,
    );
  }
}
