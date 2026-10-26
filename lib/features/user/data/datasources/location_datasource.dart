import 'dart:async';

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

    // Obs. 2 — el mapa esperaba un fix de GPS de alta precisión (en frío
    // puede tardar 10-30 s) antes de dibujarse. Ahora: 1) la última
    // posición conocida, que es instantánea, y 2) si no hay, un fix con
    // límite de tiempo. El stream de ubicación en vivo de cada pantalla
    // corrige la posición apenas llega una más precisa.
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null &&
          DateTime.now().difference(last.timestamp) <
              const Duration(minutes: 10)) {
        return LocationResult(location: LatLng(last.latitude, last.longitude));
      }
    } catch (_) {
      // Algunos dispositivos no soportan la última posición: se sigue.
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return LocationResult(
        location: LatLng(position.latitude, position.longitude),
      );
    } on TimeoutException {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        return LocationResult(
          location: LatLng(position.latitude, position.longitude),
        );
      } on TimeoutException {
        return const LocationResult(
          location: defaultCenter,
          error: 'No se pudo obtener tu ubicación. Buscando señal de GPS…',
        );
      }
    }
  }
}
