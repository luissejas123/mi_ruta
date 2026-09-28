import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
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
  // Datos para reconstruir `RutaNavegacionPage` sin argumentos nuevos (C3):
  // el pasajero puede volver a la pestaña "Rutas" y seguir viendo el viaje
  // en curso aunque la pantalla se haya cerrado. Ver `activeOrigin`.
  final LatLng? activeOrigin;
  final LatLng? activeBoardingStop;
  final LatLng? activeAlightingStop;
  final OsmRoute? activeRoute;
  final PlaceResult? activeDestination;
  final String? activeOriginName;
  final List<LatLng> activeTransitSegment;
  final List<LatLng> activeWalkStartPoints;
  final List<LatLng> activeWalkEndPoints;

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
    this.activeOrigin,
    this.activeBoardingStop,
    this.activeAlightingStop,
    this.activeRoute,
    this.activeDestination,
    this.activeOriginName,
    this.activeTransitSegment = const [],
    this.activeWalkStartPoints = const [],
    this.activeWalkEndPoints = const [],
  });

  /// Hay un viaje abordado en curso que se puede retomar desde otra
  /// pantalla (banner en "Rutas") — no solo tracking activo, sino uno con
  /// abordaje confirmado y datos suficientes para reconstruir la pantalla.
  bool get hasResumableTrip =>
      isTracking && boardingTripId != null && activeRoute != null && activeDestination != null;

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
    LatLng? activeOrigin,
    LatLng? activeBoardingStop,
    LatLng? activeAlightingStop,
    OsmRoute? activeRoute,
    PlaceResult? activeDestination,
    String? activeOriginName,
    List<LatLng>? activeTransitSegment,
    List<LatLng>? activeWalkStartPoints,
    List<LatLng>? activeWalkEndPoints,
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
      activeOrigin: activeOrigin ?? this.activeOrigin,
      activeBoardingStop: activeBoardingStop ?? this.activeBoardingStop,
      activeAlightingStop: activeAlightingStop ?? this.activeAlightingStop,
      activeRoute: activeRoute ?? this.activeRoute,
      activeDestination: activeDestination ?? this.activeDestination,
      activeOriginName: activeOriginName ?? this.activeOriginName,
      activeTransitSegment: activeTransitSegment ?? this.activeTransitSegment,
      activeWalkStartPoints: activeWalkStartPoints ?? this.activeWalkStartPoints,
      activeWalkEndPoints: activeWalkEndPoints ?? this.activeWalkEndPoints,
    );
  }

  /// Limpia todo lo que identifica un viaje en curso — al llegar al destino
  /// (fin real del tracking GPS/timer).
  NavigationState clearActiveTrip() {
    return NavigationState(
      phase: phase,
      currentPosition: currentPosition,
      elapsed: elapsed,
      isTracking: false,
      isPaused: isPaused,
      error: error,
      farePaid: farePaid,
    );
  }

  /// Limpia solo la identidad del viaje abordado (sin tocar el tracking
  /// GPS/timer, que sigue corriendo hasta llegar al destino) — al cobrarse
  /// el viaje (aviso de bajada, QR o el respaldo automático de
  /// `DriverService`), para que el banner de "viaje en curso" desaparezca
  /// aunque el pasajero siga viajando hasta bajarse (C3).
  NavigationState clearBoardingData() {
    return NavigationState(
      phase: phase,
      currentPosition: currentPosition,
      elapsed: elapsed,
      isTracking: isTracking,
      isPaused: isPaused,
      error: error,
      farePaid: farePaid,
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
    activeOrigin,
    activeBoardingStop,
    activeAlightingStop,
    activeRoute,
    activeDestination,
    activeOriginName,
    activeTransitSegment,
    activeWalkStartPoints,
    activeWalkEndPoints,
  ];
}
