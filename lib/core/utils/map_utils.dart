import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utilidades de mapa reutilizables en toda la app.
class MapUtils {
  MapUtils._();

  /// Anima la cámara de [controller] para encuadrar todos los [points]
  /// con el [padding] en píxeles dado.
  ///
  /// Si hay menos de 2 puntos, hace zoom a [points.first] en nivel 14.
  static void fitBounds(
    GoogleMapController controller,
    List<LatLng> points, {
    double padding = 60,
  }) {
    if (points.isEmpty) return;
    if (points.length < 2) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(points.first, 14));
      return;
    }

    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        padding,
      ),
    );
  }
}
