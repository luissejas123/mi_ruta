import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';

/// Resultado de una búsqueda de ruta cercana
class RouteMatch {
  final OsmRoute route;

  /// Distancia mínima en metros desde algún punto de la ruta al destino
  final double distanceMeters;

  const RouteMatch({required this.route, required this.distanceMeters});
}

/// Servicio para encontrar rutas de Cochabamba que pasan cerca de un punto dado
class RouteFinderService {
  /// Devuelve hasta [maxResults] rutas cuyo trazado pasa dentro de
  /// [maxDistanceMeters] metros de [target], ordenadas de más a menos cercana.
  ///
  /// Para performance, muestrea cada [sampleStep] puntos del polyline.
  static List<RouteMatch> findNearby(
    LatLng target,
    List<OsmRoute> routes, {
    int maxResults = 8,
    double maxDistanceMeters = 2000,
    int sampleStep = 8,
  }) {
    final matches = <RouteMatch>[];

    for (final route in routes) {
      double minDist = double.infinity;

      outer:
      for (final segment in route.segments) {
        for (var i = 0; i < segment.length; i += sampleStep) {
          final pt = segment[i];
          final d = Geolocator.distanceBetween(
            target.latitude,
            target.longitude,
            pt.latitude,
            pt.longitude,
          );
          if (d < minDist) minDist = d;
          if (minDist < 50) break outer; // ya es suficientemente cercana
        }
      }

      if (minDist <= maxDistanceMeters) {
        matches.add(RouteMatch(route: route, distanceMeters: minDist));
      }
    }

    matches.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return matches.take(maxResults).toList();
  }

  /// Devuelve rutas que pasan cerca del [destination], ordenadas por cercanía
  /// al [userLocation] si se proporciona.
  ///
  /// Útil para mostrar sugerencias de ruta priorizando las más convenientes
  /// para el usuario.
  static List<RouteMatch> findNearbyForTrip({
    required LatLng destination,
    required List<OsmRoute> routes,
    LatLng? userLocation,
    double maxDestDistanceMeters = 2000,
    double maxUserDistanceMeters = 5000,
  }) {
    final nearDest = findNearby(
      destination,
      routes,
      maxResults: 999,
      maxDistanceMeters: maxDestDistanceMeters,
    );
    if (nearDest.isEmpty || userLocation == null) return nearDest;

    final nearUser = findNearby(
      userLocation,
      routes,
      maxResults: 999,
      maxDistanceMeters: maxUserDistanceMeters,
    );
    final userDistMap = {
      for (final m in nearUser) m.route.id: m.distanceMeters,
    };
    return List.of(nearDest)..sort(
      (a, b) => (userDistMap[a.route.id] ?? double.infinity).compareTo(
        userDistMap[b.route.id] ?? double.infinity,
      ),
    );
  }

  /// Devuelve rutas que pasan cerca tanto del [origin] como del [destination],
  /// ordenadas por cercanía al [origin] (parada de abordaje).
  ///
  /// Si ninguna ruta cubre ambos puntos, devuelve las rutas cercanas al
  /// [destination] como fallback.
  static List<RouteMatch> findForTrip({
    required LatLng origin,
    required LatLng destination,
    required List<OsmRoute> routes,
    double maxDistanceMeters = 2000,
  }) {
    // sampleStep: 2 para mayor precisión al calcular proximidad
    final nearDest = findNearby(
      destination,
      routes,
      maxResults: 999,
      maxDistanceMeters: maxDistanceMeters,
      sampleStep: 2,
    );
    final nearOrigin = findNearby(
      origin,
      routes,
      maxResults: 999,
      maxDistanceMeters: maxDistanceMeters,
      sampleStep: 2,
    );

    final originIds = nearOrigin.map((m) => m.route.id).toSet();
    final originDistMap = {
      for (final m in nearOrigin) m.route.id: m.distanceMeters,
    };

    var matches = nearDest
        .where((m) => originIds.contains(m.route.id))
        .toList();
    if (matches.isEmpty) matches = nearDest.toList();

    // Ordenar por cercanía al usuario (distancia a pie hasta la parada de abordaje)
    matches.sort(
      (a, b) => (originDistMap[a.route.id] ?? double.infinity).compareTo(
        originDistMap[b.route.id] ?? double.infinity,
      ),
    );

    // Retornar con distancia desde el usuario para mostrar correctamente en tarjetas
    return matches
        .map(
          (m) => RouteMatch(
            route: m.route,
            distanceMeters: originDistMap[m.route.id] ?? m.distanceMeters,
          ),
        )
        .toList();
  }
}
