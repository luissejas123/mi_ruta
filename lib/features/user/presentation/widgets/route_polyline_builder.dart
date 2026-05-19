import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Constructor reutilizable para polylines del mapa.
class RoutePolylineBuilder {
  /// Construye polylines a partir de listas de LatLng.
  static Set<Polyline> buildPolylines({
    required String walkingPolylineId,
    required List<LatLng> walkingPoints,
    required String transitPolylineId,
    required List<LatLng> transitPoints,
    required String suggestedPolylineId,
    required List<LatLng> suggestedPoints,
  }) {
    final Set<Polyline> polylines = {};

    // Walking polyline (punteada, roja)
    if (walkingPoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: PolylineId(walkingPolylineId),
          points: walkingPoints,
          color: const Color.fromARGB(255, 255, 87, 34),
          width: 4,
          geodesic: true,
          patterns: [PatternItem.dash(30), PatternItem.gap(30)],
        ),
      );
    }

    // Transit polyline (sólida, azul)
    if (transitPoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: PolylineId(transitPolylineId),
          points: transitPoints,
          color: Colors.blue,
          width: 5,
          geodesic: true,
        ),
      );
    }

    // Suggested polyline (punteada, gris)
    if (suggestedPoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: PolylineId(suggestedPolylineId),
          points: suggestedPoints,
          color: Colors.grey,
          width: 3,
          geodesic: true,
          patterns: [PatternItem.dash(15), PatternItem.gap(15)],
        ),
      );
    }

    return polylines;
  }
}

// Re-export de Color para que el usuario no importe dos veces
extension ColorForPolyline on Color {
  // Helper para facilitar uso
}
