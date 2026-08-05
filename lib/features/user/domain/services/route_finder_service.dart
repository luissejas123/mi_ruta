import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/services/trip_segment_service.dart';

/// Resultado de una búsqueda de ruta cercana
class RouteMatch {
  final OsmRoute route;

  /// Distancia caminando desde el usuario hasta la parada de abordaje (metros)
  final double distanceMeters;

  /// Distancia real del trayecto en bus/trufi (boarding → alighting) (metros)
  final double transitMeters;

  /// Distancia caminando desde la parada de bajada hasta el destino (metros)
  final double walkFromAlightMeters;

  const RouteMatch({
    required this.route,
    required this.distanceMeters,
    this.transitMeters = 0,
    this.walkFromAlightMeters = 0,
  });

  /// Tiempo total estimado en minutos
  /// Caminar: 80 m/min  |  Bus: 250 m/min
  double get totalMinutes =>
      (distanceMeters / 80) +
      (transitMeters / 250) +
      (walkFromAlightMeters / 80);
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

  /// Devuelve las [maxResults] rutas más eficientes para viajar de [origin]
  /// a [destination], considerando:
  ///   - Distancia caminando hasta la parada de abordaje (≤ [maxWalkMeters])
  ///   - Distancia real en bus entre abordaje y bajada
  ///   - Distancia caminando desde la bajada al destino
  ///
  /// Score = walkToBoard × 3 + transitMeters + walkFromAlight × 2
  /// (caminar cuesta ~3× más que ir en bus en tiempo percibido)
  static List<RouteMatch> findForTrip({
    required LatLng origin,
    required LatLng destination,
    required List<OsmRoute> routes,
    double maxWalkMeters = 800, // ~10 min caminando a 80m/min
    int maxResults = 10,
  }) {
    final scored = <_ScoredRoute>[];

    for (final route in routes) {
      // 1. Filtro rápido: ¿hay puntos del polyline a ≤ maxWalkMeters del origen?
      bool originOk = false;
      for (final seg in route.segments) {
        if (seg.isEmpty) continue;
        for (int i = 0; i < seg.length; i += 5) {
          final d = Geolocator.distanceBetween(
            origin.latitude,
            origin.longitude,
            seg[i].latitude,
            seg[i].longitude,
          );
          if (d <= maxWalkMeters) {
            originOk = true;
            break;
          }
        }
        if (originOk) break;
      }
      if (!originOk) continue;

      // 2. Calcular segmento real (boarding → alighting)
      final segment = TripSegmentService.compute(
        route: route,
        origin: origin,
        destination: destination,
      );

      if (segment.transitPoints.isEmpty) continue;

      // 3. Distancias precisas (ya calculadas en compute, aproximamos aquí)
      final walkToBoard = Geolocator.distanceBetween(
        origin.latitude,
        origin.longitude,
        segment.boardingStop.latitude,
        segment.boardingStop.longitude,
      );

      if (walkToBoard > maxWalkMeters) continue;

      final walkFromAlight = Geolocator.distanceBetween(
        segment.alightingStop.latitude,
        segment.alightingStop.longitude,
        destination.latitude,
        destination.longitude,
      );

      // 4. Distancia en bus: aproximación rápida (~111m por grado de latitud)
      // En lugar de sumar cada punto, usamos la distancia euclidiana
      // multiplicada por un factor (los polylines no son rectos)
      final boardLat = segment.boardingStop.latitude;
      final boardLng = segment.boardingStop.longitude;
      final alightLat = segment.alightingStop.latitude;
      final alightLng = segment.alightingStop.longitude;

      final dLat = (alightLat - boardLat) * 111000; // ~111km por grado
      final dLng =
          (alightLng - boardLng) *
          111000 *
          (boardLat.abs() < 85 ? cos(boardLat * pi / 180) : 1);

      // Aproximación: distancia euclidiana × 1.3 (polylines tienen curvas)
      double transitMeters = sqrt(dLat * dLat + dLng * dLng) * 1.3;

      // Si el segmento es ridículamente corto, ignorar
      if (transitMeters < 50) continue;

      // 5. Score ponderado
      final score = walkToBoard * 3.0 + transitMeters + walkFromAlight * 2.0;

      scored.add(
        _ScoredRoute(
          route: route,
          walkToBoard: walkToBoard,
          transitMeters: transitMeters,
          walkFromAlight: walkFromAlight,
          score: score,
        ),
      );
    }

    scored.sort((a, b) => a.score.compareTo(b.score));

    return scored.take(maxResults).map((s) {
      return RouteMatch(
        route: s.route,
        distanceMeters: s.walkToBoard,
        transitMeters: s.transitMeters,
        walkFromAlightMeters: s.walkFromAlight,
      );
    }).toList();
  }
}

/// Clase interna de apoyo para ordenar por score antes de construir RouteMatch
class _ScoredRoute {
  final OsmRoute route;
  final double walkToBoard;
  final double transitMeters;
  final double walkFromAlight;
  final double score;

  const _ScoredRoute({
    required this.route,
    required this.walkToBoard,
    required this.transitMeters,
    required this.walkFromAlight,
    required this.score,
  });
}
