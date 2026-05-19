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

  /// Formatea una duración como texto compacto: "05:32" o "1:05:32".
  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
