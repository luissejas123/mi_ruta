import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utilidades de distancia geográfica reutilizables en toda la app.
class DistanceUtils {
  DistanceUtils._();

  /// Distancia en metros entre [a] y [b] usando la fórmula de Haversine.
  static double metersApprox(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);
    final hav =
        sinLat * sinLat +
        math.cos(a.latitude * math.pi / 180) *
            math.cos(b.latitude * math.pi / 180) *
            sinLng *
            sinLng;
    return 2 * r * math.asin(math.sqrt(hav));
  }

  /// Formatea una distancia en metros como texto legible: "250 m" o "1.3 km".
  static String formatMeters(double m) =>
      m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

  /// Distancia mínima en metros entre [point] y el segmento [a]-[b].
  /// Proyecta [point] sobre un plano local aproximado (metros) centrado en
  /// [a] y clampea al segmento — suficiente precisión para radios de
  /// cientos de metros (mismo orden de aproximación que ya usa el resto
  /// del código, ver `radiusDeg = radiusMeters / 111000` en bus_stop_service).
  static double _pointToSegmentMeters(LatLng point, LatLng a, LatLng b) {
    const metersPerDegLat = 111000.0;
    final metersPerDegLng = 111000.0 * math.cos(a.latitude * math.pi / 180);

    double toX(double lng) => (lng - a.longitude) * metersPerDegLng;
    double toY(double lat) => (lat - a.latitude) * metersPerDegLat;

    const ax = 0.0, ay = 0.0;
    final bx = toX(b.longitude), by = toY(b.latitude);
    final px = toX(point.longitude), py = toY(point.latitude);

    final abx = bx - ax, aby = by - ay;
    final lenSq = abx * abx + aby * aby;
    var t = lenSq == 0 ? 0.0 : ((px - ax) * abx + (py - ay) * aby) / lenSq;
    t = t.clamp(0.0, 1.0);
    final cx = ax + t * abx, cy = ay + t * aby;
    final dx = px - cx, dy = py - cy;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Distancia mínima en metros entre [point] y la polilínea completa
  /// [polyline] (mínimo sobre todos sus segmentos consecutivos). Usada para
  /// "qué rutas pasan cerca de mí" cuando no hay paradas puntuales reales
  /// que consultar.
  static double distanceToPolylineMeters(LatLng point, List<LatLng> polyline) {
    if (polyline.isEmpty) return double.infinity;
    if (polyline.length == 1) return metersApprox(point, polyline.first);
    var minDist = double.infinity;
    for (var i = 0; i < polyline.length - 1; i++) {
      final d = _pointToSegmentMeters(point, polyline[i], polyline[i + 1]);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  /// Formatea una duración como texto compacto: "05:32" o "1:05:32".
  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
