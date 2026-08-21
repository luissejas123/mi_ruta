import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/domain/services/trip_phase_service.dart';

/// Servicio con utilidades para la navegación
class NavigationUtilsService {
  /// Calcula la distancia entre dos coordenadas
  static double distanceBetween(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  /// Calcula los metros restantes según la fase actual
  static double calculateRemainingMeters({
    required TripPhase phase,
    required LatLng? currentPosition,
    required LatLng boardingStop,
    required LatLng alightingStop,
    required LatLng destination,
  }) {
    if (currentPosition == null) return 0;

    switch (phase) {
      case TripPhase.walkStart:
        return distanceBetween(currentPosition, boardingStop);
      case TripPhase.onBus:
        return distanceBetween(currentPosition, alightingStop);
      case TripPhase.walkEnd:
      case TripPhase.arrived:
        return distanceBetween(currentPosition, destination);
    }
  }
}
