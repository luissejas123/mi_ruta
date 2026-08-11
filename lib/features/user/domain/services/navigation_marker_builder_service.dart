import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Servicio para construir markers en la pantalla de navegación
class NavigationMarkerBuilderService {
  /// Construye los markers para la navegación
  static Set<Marker> buildMarkers({
    required LatLng? origin,
    required LatLng boardingStop,
    required LatLng alightingStop,
    required LatLng destination,
    required String destinationName,
    required LatLng? currentPosition,
    required BitmapDescriptor? locationIcon,
  }) {
    final markers = <Marker>{};

    // Marker de origen
    if (origin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: origin,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Tu origen'),
        ),
      );
    }

    // Marker de parada de subida
    markers.add(
      Marker(
        markerId: const MarkerId('boarding'),
        position: boardingStop,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: const InfoWindow(title: '🚌 Subir aquí'),
      ),
    );

    // Marker de parada de bajada
    markers.add(
      Marker(
        markerId: const MarkerId('alighting'),
        position: alightingStop,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: '🔔 Bajar aquí'),
      ),
    );

    // Marker de destino
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: destinationName),
      ),
    );

    // Marker de ubicación actual del usuario
    if (currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: currentPosition,
          icon:
              locationIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndex: 10,
        ),
      );
    }

    return markers;
  }
}
