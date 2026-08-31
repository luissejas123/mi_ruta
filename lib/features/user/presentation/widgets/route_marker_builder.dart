import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Constructor reutilizable para marcadores del mapa.
class RouteMarkerBuilder {
  /// Construye marcadores para origen, destino y paradas.
  static Set<Marker> buildMarkers({
    required String userMarkerIdString,
    required LatLng userLocation,
    required String originMarkerIdString,
    required LatLng originLocation,
    required String destinationMarkerIdString,
    required LatLng destinationLocation,
    String? boardingMarkerIdString,
    LatLng? boardingLocation,
    String? alightingMarkerIdString,
    LatLng? alightingLocation,
    VoidCallback? onUserMarkerTap,
    VoidCallback? onOriginMarkerTap,
    VoidCallback? onDestinationMarkerTap,
    VoidCallback? onBoardingMarkerTap,
    VoidCallback? onAlightingMarkerTap,
  }) {
    final Set<Marker> markers = {};

    // Marcador de usuario (azul)
    markers.add(
      Marker(
        markerId: MarkerId(userMarkerIdString),
        position: userLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        onTap: onUserMarkerTap,
        infoWindow: const InfoWindow(title: 'Tu ubicación'),
      ),
    );

    // Marcador de origen (verde)
    markers.add(
      Marker(
        markerId: MarkerId(originMarkerIdString),
        position: originLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        onTap: onOriginMarkerTap,
        infoWindow: const InfoWindow(title: 'Origen'),
      ),
    );

    // Marcador de destino (rojo)
    markers.add(
      Marker(
        markerId: MarkerId(destinationMarkerIdString),
        position: destinationLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: onDestinationMarkerTap,
        infoWindow: const InfoWindow(title: 'Destino'),
      ),
    );

    // Marcador de parada de abordaje (naranja)
    if (boardingLocation != null && boardingMarkerIdString != null) {
      markers.add(
        Marker(
          markerId: MarkerId(boardingMarkerIdString),
          position: boardingLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          onTap: onBoardingMarkerTap,
          infoWindow: const InfoWindow(title: 'Parada de Abordaje'),
        ),
      );
    }

    // Marcador de parada de bajada (violeta)
    if (alightingLocation != null && alightingMarkerIdString != null) {
      markers.add(
        Marker(
          markerId: MarkerId(alightingMarkerIdString),
          position: alightingLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          onTap: onAlightingMarkerTap,
          infoWindow: const InfoWindow(title: 'Parada de Bajada'),
        ),
      );
    }

    return markers;
  }
}
