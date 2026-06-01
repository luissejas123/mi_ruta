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

  const NavigationState({
    required this.phase,
    this.currentPosition,
    this.elapsed = Duration.zero,
    this.isTracking = false,
    this.isPaused = false,
    this.error,
  });

  NavigationState copyWith({
    TripPhase? phase,
    LatLng? currentPosition,
    Duration? elapsed,
    bool? isTracking,
    bool? isPaused,
    String? error,
  }) {
    return NavigationState(
      phase: phase ?? this.phase,
      currentPosition: currentPosition ?? this.currentPosition,
      elapsed: elapsed ?? this.elapsed,
      isTracking: isTracking ?? this.isTracking,
      isPaused: isPaused ?? this.isPaused,
      error: error ?? this.error,
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
  ];
}
