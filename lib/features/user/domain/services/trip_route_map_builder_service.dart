import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_line_state.dart';

/// Servicio para construir polylines y markers para la visualización de ruta de línea
class TripRouteMapBuilderService {
  static const Color _transitColor = Color(0xFFFBC02D);

  /// Construye los polylines de la ruta (caminatas + transporte)
  static Set<Polyline> buildPolylines({
    required TripSegmentData tripSegment,
    required WalkingPaths walkingPaths,
    required OsmRoute route,
    required PlaceResult destination,
    required LatLng? origin,
  }) {
    final polylines = <Polyline>{};

    // Polyline del transporte (amarillo sólido)
    if (tripSegment.transitPoints.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('transit'),
          points: tripSegment.transitPoints,
          color: _transitColor,
          width: 6,
        ),
      );
    }

    // Polyline de caminata inicial (gris punteado)
    if (origin != null) {
      final startWalkPts = walkingPaths.startWalkPath.isNotEmpty
          ? walkingPaths.startWalkPath
          : [origin, tripSegment.boardingStop];
      polylines.add(
        Polyline(
          polylineId: const PolylineId('walk_start'),
          points: startWalkPts,
          color: Colors.grey.shade700,
          width: 4,
          patterns: [PatternItem.dash(16), PatternItem.gap(12)],
        ),
      );
    }

    // Polyline de caminata final (gris punteado)
    final endWalkPts = walkingPaths.endWalkPath.isNotEmpty
        ? walkingPaths.endWalkPath
        : [tripSegment.alightingStop, destination.latLng];
    polylines.add(
      Polyline(
        polylineId: const PolylineId('walk_end'),
        points: endWalkPts,
        color: Colors.grey.shade700,
        width: 4,
        patterns: [PatternItem.dash(16), PatternItem.gap(12)],
      ),
    );

    return polylines;
  }

  /// Construye los markers de la ruta
  static Set<Marker> buildMarkers({
    required TripSegmentData tripSegment,
    required OsmRoute route,
    required PlaceResult destination,
    required LatLng? origin,
  }) {
    final markers = <Marker>{};

    // Marker de origen (si existe)
    if (origin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('origen'),
          position: origin,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: '📍 Punto de partida'),
        ),
      );
    }

    // Marker de subida (amarillo)
    markers.add(
      Marker(
        markerId: const MarkerId('boarding'),
        position: tripSegment.boardingStop,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: const InfoWindow(title: '🚌 Subir aquí'),
      ),
    );

    // Marker de bajada (naranja)
    markers.add(
      Marker(
        markerId: const MarkerId('alighting'),
        position: tripSegment.alightingStop,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: '🔔 Bajar aquí'),
      ),
    );

    // Marker de destino (azul)
    markers.add(
      Marker(
        markerId: const MarkerId('destino'),
        position: destination.latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: '🏁 ${destination.name}'),
      ),
    );

    return markers;
  }

  /// Obtiene los puntos para los bounds del mapa
  static List<LatLng> getBoundsPoints({
    required TripSegmentData tripSegment,
    required PlaceResult destination,
    required LatLng? origin,
  }) {
    return [
      if (origin != null) origin,
      ...tripSegment.transitPoints,
      destination.latLng,
    ];
  }
}
