import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/domain/services/trip_phase_service.dart';

class NavigationState extends Equatable {
  final TripPhase phase;
  final LatLng? currentPosition;
  final Duration elapsed;
  final bool isTracking;
  final bool isPaused;
  final String? error;
  // Viaje de abordaje (Bloque 2, paso 3) — null hasta que el pasajero
  // escanea el QR fijo de la unidad. `farePaid` queda null hasta el "aviso
  // de bajada" (o el cobro de respaldo por tarifa máxima, ver DriverService).
  final String? boardingTripId;
  final String? boardingDriverId;
  final String? boardingRouteRef;
  final double? farePaid;

  const NavigationState({
    required this.phase,
    this.currentPosition,
    this.elapsed = Duration.zero,
    this.isTracking = false,
    this.isPaused = false,
    this.error,
    this.boardingTripId,
    this.boardingDriverId,
    this.boardingRouteRef,
    this.farePaid,
  });

  NavigationState copyWith({
    TripPhase? phase,
    LatLng? currentPosition,
    Duration? elapsed,
    bool? isTracking,
    bool? isPaused,
    String? error,
    String? boardingTripId,
    String? boardingDriverId,
    String? boardingRouteRef,
    double? farePaid,
  }) {
    return NavigationState(
      phase: phase ?? this.phase,
      currentPosition: currentPosition ?? this.currentPosition,
      elapsed: elapsed ?? this.elapsed,
      isTracking: isTracking ?? this.isTracking,
      isPaused: isPaused ?? this.isPaused,
      error: error ?? this.error,
      boardingTripId: boardingTripId ?? this.boardingTripId,
      boardingDriverId: boardingDriverId ?? this.boardingDriverId,
      boardingRouteRef: boardingRouteRef ?? this.boardingRouteRef,
      farePaid: farePaid ?? this.farePaid,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    currentPosition,
    elapsed,
    isTracking,
    isPaused,
    error,
    boardingTripId,
    boardingDriverId,
    boardingRouteRef,
    farePaid,
  ];
}
