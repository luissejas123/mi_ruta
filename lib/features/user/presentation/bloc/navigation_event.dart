import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

/// Inicia el tracking de GPS y el timer.
///
/// [route]/[destinationInfo]/[originName]/[transitSegment]/[walkStartPoints]/
/// [walkEndPoints] no los usa el tracking en sí (eso ya lo cubren
/// [boardingStop]/[alightingStop]/[destination]) — quedan guardados en el
/// estado únicamente para poder reconstruir `RutaNavegacionPage` desde cero
/// si el pasajero vuelve a la pestaña "Rutas" con un viaje en curso (C3,
/// ver `RutasInicioPage`).
class NavigationStarted extends NavigationEvent {
  final LatLng? origin;
  final LatLng boardingStop;
  final LatLng alightingStop;
  final LatLng destination;
  final OsmRoute route;
  final PlaceResult destinationInfo;
  final String originName;
  final List<LatLng> transitSegment;
  final List<LatLng> walkStartPoints;
  final List<LatLng> walkEndPoints;
  // Abordaje ya confirmado antes de llegar acá (ConfirmarAbordajePage,
  // Bloque 2 paso 3, rediseño 2026-09-14) — si vienen puestos, "Aviso de
  // bajada" queda disponible desde el inicio, sin esperar ninguna fase.
  final String? initialBoardingTripId;
  final String? initialBoardingDriverId;
  final String? initialBoardingRouteRef;

  const NavigationStarted({
    required this.origin,
    required this.boardingStop,
    required this.alightingStop,
    required this.destination,
    required this.route,
    required this.destinationInfo,
    required this.originName,
    required this.transitSegment,
    required this.walkStartPoints,
    required this.walkEndPoints,
    this.initialBoardingTripId,
    this.initialBoardingDriverId,
    this.initialBoardingRouteRef,
  });

  @override
  List<Object?> get props => [
    origin,
    boardingStop,
    alightingStop,
    destination,
    route,
    destinationInfo,
    originName,
    transitSegment,
    walkStartPoints,
    walkEndPoints,
    initialBoardingTripId,
    initialBoardingDriverId,
    initialBoardingRouteRef,
  ];
}

/// Actualiza la posición actual del usuario
class PositionUpdated extends NavigationEvent {
  final LatLng position;

  const PositionUpdated(this.position);

  @override
  List<Object?> get props => [position];
}

/// Evento de error en el tracking
class TrackingError extends NavigationEvent {
  final String message;

  const TrackingError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Pausa el tracking cuando la app entra en background
class NavigationPaused extends NavigationEvent {
  const NavigationPaused();
}

/// Reanuda el tracking cuando la app vuelve a foreground
class NavigationResumed extends NavigationEvent {
  const NavigationResumed();
}

/// Detiene el tracking (cleanup final - solo cuando termina el viaje)
class NavigationStopped extends NavigationEvent {
  const NavigationStopped();
}

/// Tick periódico del temporizador de viaje
class TimerTick extends NavigationEvent {
  const TimerTick();
}

/// Se cobró la tarifa por distancia tras el "aviso de bajada".
class FareCharged extends NavigationEvent {
  final double amount;

  const FareCharged(this.amount);

  @override
  List<Object?> get props => [amount];
}
