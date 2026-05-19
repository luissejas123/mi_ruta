import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Fases del viaje en transporte público.
enum TripPhase { walkStart, onBus, walkEnd, arrived }

/// Servicio de dominio: detecta si el usuario avanzó a la siguiente fase
/// comparando su posición con los puntos clave del trayecto.
class TripPhaseService {
  TripPhaseService._();

  static const double defaultThresholdMeters = 50.0;

  /// Devuelve la nueva fase según la posición actual.
  /// Si la fase no cambia, devuelve [current] sin modificar.
  static TripPhase advance({
    required TripPhase current,
    required LatLng position,
    required LatLng boardingStop,
    required LatLng alightingStop,
    required LatLng destination,
    double threshold = defaultThresholdMeters,
  }) {
    switch (current) {
      case TripPhase.walkStart:
        if (_dist(position, boardingStop) < threshold) return TripPhase.onBus;
        break;
      case TripPhase.onBus:
        if (_dist(position, alightingStop) < threshold)
          return TripPhase.walkEnd;
        break;
      case TripPhase.walkEnd:
        if (_dist(position, destination) < threshold) return TripPhase.arrived;
        break;
      case TripPhase.arrived:
        break;
    }
    return current;
  }

  static double _dist(LatLng a, LatLng b) => Geolocator.distanceBetween(
    a.latitude,
    a.longitude,
    b.latitude,
    b.longitude,
  );
}
