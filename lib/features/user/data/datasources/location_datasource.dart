import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Resultado de la solicitud de ubicación actual del dispositivo.
class LocationResult {
  /// Coordenadas obtenidas (o el centro por defecto si no hay permisos/servicio).
  final LatLng location;

  /// Mensaje de error si la ubicación no se pudo obtener; null si fue exitosa.
  final String? error;

  const LocationResult({required this.location, this.error});

  bool get hasError => error != null;
}

/// Accede al GPS del dispositivo: solicita permisos y obtiene la posición actual.
class LocationDatasource {
  /// Centro de Cochabamba usado como fallback cuando no hay GPS disponible.
  static const LatLng defaultCenter = LatLng(-17.391032, -66.1568);

  /// Devuelve la posición actual del dispositivo.
  /// Si el servicio está desactivado o el permiso es denegado, devuelve
  /// [defaultCenter] con un mensaje de error en [LocationResult.error].
  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
        location: defaultCenter,
        error: 'Activa el servicio de ubicación para ver tu posición real.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const LocationResult(
        location: defaultCenter,
        error: 'Permiso de ubicación denegado. Usa el mapa manualmente.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LocationResult(
      location: LatLng(position.latitude, position.longitude),
    );
  }
}
