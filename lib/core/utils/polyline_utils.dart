import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utilidades para manipulación de polylines.
class PolylineUtils {
  PolylineUtils._();

  /// Recorta [points] devolviendo solo los puntos desde el más cercano a
  /// [current] hasta el final, eliminando el tramo ya recorrido.
  static List<LatLng> trimToPosition(List<LatLng> points, LatLng current) {
    if (points.length < 2) return points;
    double minDist = double.infinity;
    int closestIdx = 0;
    for (int i = 0; i < points.length; i++) {
      final d = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        points[i].latitude,
        points[i].longitude,
      );
      if (d < minDist) {
        minDist = d;
        closestIdx = i;
      }
    }
    return points.sublist(closestIdx);
  }
}
