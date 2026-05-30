import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/domain/services/trip_phase_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/navigation_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  static const _advanceThresholdMeters = 50.0;

  late final LatLng _boardingStop;
  late final LatLng _alightingStop;
  late final LatLng _destination;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  late final DateTime _startTime;

  NavigationBloc()
    : super(NavigationState(phase: TripPhase.walkStart, isTracking: false)) {
    on<NavigationStarted>(_onNavigationStarted);
    on<PositionUpdated>(_onPositionUpdated);
    on<TrackingError>(_onTrackingError);
    on<NavigationStopped>(_onNavigationStopped);
  }

  /// Inicia el tracking GPS y el timer
  Future<void> _onNavigationStarted(
    NavigationStarted event,
    Emitter<NavigationState> emit,
  ) async {
    _startTime = DateTime.now();
    _boardingStop = event.boardingStop;
    _alightingStop = event.alightingStop;
    _destination = event.destination;

    final initialPhase = event.origin != null
        ? TripPhase.walkStart
        : TripPhase.onBus;

    emit(state.copyWith(phase: initialPhase, isTracking: true));

    _startTimer(emit);
    await _startGpsTracking();
  }

  /// Maneja actualización de posición
  Future<void> _onPositionUpdated(
    PositionUpdated event,
    Emitter<NavigationState> emit,
  ) async {
    final newPhase = TripPhaseService.advance(
      current: state.phase,
      position: event.position,
      boardingStop: _boardingStop,
      alightingStop: _alightingStop,
      destination: _destination,
      threshold: _advanceThresholdMeters,
    );

    emit(state.copyWith(phase: newPhase, currentPosition: event.position));
  }

  /// Maneja errores de tracking
  Future<void> _onTrackingError(
    TrackingError event,
    Emitter<NavigationState> emit,
  ) async {
    emit(state.copyWith(error: event.message, isTracking: false));
  }

  /// Detiene el tracking
  Future<void> _onNavigationStopped(
    NavigationStopped event,
    Emitter<NavigationState> emit,
  ) async {
    await _cleanup();
    emit(state.copyWith(isTracking: false));
  }

  /// Inicia el timer que actualiza elapsed cada segundo
  void _startTimer(Emitter<NavigationState> emit) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(_startTime);
      emit(state.copyWith(elapsed: elapsed));
    });
  }

  /// Inicia el tracking de GPS con permisos y configuración
  Future<void> _startGpsTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        add(const TrackingError('Servicio de ubicación deshabilitado'));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          add(const TrackingError('Permisos de ubicación denegados'));
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        add(
          const TrackingError('Permisos de ubicación negados permanentemente'),
        );
        return;
      }

      // Obtener posición inicial
      final initial = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final initialPos = LatLng(initial.latitude, initial.longitude);
      add(PositionUpdated(initialPos));

      // Escuchar cambios de posición
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen(
            (Position pos) {
              add(PositionUpdated(LatLng(pos.latitude, pos.longitude)));
            },
            onError: (error) {
              add(TrackingError(error.toString()));
            },
          );
    } catch (e) {
      add(TrackingError(e.toString()));
    }
  }

  /// Limpia recursos (streams, timers)
  Future<void> _cleanup() async {
    await _positionSubscription?.cancel();
    _timer?.cancel();
  }

  @override
  Future<void> close() async {
    await _cleanup();
    await super.close();
  }
}
