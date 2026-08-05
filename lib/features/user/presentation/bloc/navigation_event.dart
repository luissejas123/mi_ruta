import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

/// Inicia el tracking de GPS y el timer
class NavigationStarted extends NavigationEvent {
  final LatLng? origin;
  final LatLng boardingStop;
  final LatLng alightingStop;
  final LatLng destination;

  const NavigationStarted({
    required this.origin,
    required this.boardingStop,
    required this.alightingStop,
    required this.destination,
  });

  @override
  List<Object?> get props => [origin, boardingStop, alightingStop, destination];
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
