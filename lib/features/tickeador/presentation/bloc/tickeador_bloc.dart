import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/tickeador/domain/services/tickeador_service.dart';
import 'package:mi_ruta/features/tickeador/presentation/bloc/tickeador_event.dart';
import 'package:mi_ruta/features/tickeador/presentation/bloc/tickeador_state.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';

/// BLoC de la feature Tickeador.
///
/// Maneja la carga de la información del tickeador, la búsqueda de vehículos,
/// el registro de salidas/llegadas y la actividad reciente.
class TickeadorBloc extends Bloc<TickeadorEvent, TickeadorState> {
  final TickeadorService _service;

  TickeadorBloc({required TickeadorService service})
    : _service = service,
      super(const TickeadorInitial()) {
    on<CargarTickeadorEvent>(_onCargarTickeador);
    on<BuscarVehiculoEvent>(_onBuscarVehiculo);
    on<MarcarSalidaEvent>(_onMarcarSalida);
    on<MarcarLlegadaEvent>(_onMarcarLlegada);
    on<CargarActividadEvent>(_onCargarActividad);
    on<ValidateTripQr>(_onValidateTripQr);
    on<LoadVerificationHistory>(_onLoadVerificationHistory);
  }

  /// Carga la información del tickeador (tickeador_info).
  Future<void> _onCargarTickeador(
    CargarTickeadorEvent event,
    Emitter<TickeadorState> emit,
  ) async {
    emit(const TickeadorLoading());
    try {
      final tickeador = await _service.getTickeadorInfo(event.uid);
      emit(TickeadorLoaded(tickeador: tickeador));
    } catch (e) {
      emit(TickeadorError(message: e.toString()));
    }
  }

  /// Busca un vehículo por placa.
  Future<void> _onBuscarVehiculo(
    BuscarVehiculoEvent event,
    Emitter<TickeadorState> emit,
  ) async {
    emit(const TickeadorLoading());
    try {
      final vehicle = await _service.buscarVehiculoPorPlaca(event.placa);
      if (vehicle == null) {
        emit(const VehicleNotFound());
      } else {
        emit(VehicleFound(vehicle: vehicle));
      }
    } catch (e) {
      emit(TickeadorError(message: e.toString()));
    }
  }

  /// Marca la salida de un vehículo.
  Future<void> _onMarcarSalida(
    MarcarSalidaEvent event,
    Emitter<TickeadorState> emit,
  ) async {
    emit(const TickeadorLoading());
    try {
      await _service.marcarSalida(
        tickeadorId: event.tickeadorId,
        stationName: event.stationName,
        vehicle: event.vehicle,
      );
      emit(const StationLogSuccess(message: 'Salida registrada correctamente'));
      // Refrescar la actividad reciente
      emit(const TickeadorLoading());
      final logs = await _service.getActividadReciente(event.tickeadorId);
      emit(ActividadLoaded(logs: logs));
      // Mantener el vehículo seleccionado visible
      emit(VehicleFound(vehicle: event.vehicle));
    } catch (e) {
      emit(TickeadorError(message: e.toString()));
    }
  }

  /// Marca la llegada de un vehículo.
  Future<void> _onMarcarLlegada(
    MarcarLlegadaEvent event,
    Emitter<TickeadorState> emit,
  ) async {
    emit(const TickeadorLoading());
    try {
      await _service.marcarLlegada(
        tickeadorId: event.tickeadorId,
        stationName: event.stationName,
        vehicle: event.vehicle,
      );
      emit(const StationLogSuccess(message: 'Llegada registrada correctamente'));
      // Refrescar la actividad reciente
      emit(const TickeadorLoading());
      final logs = await _service.getActividadReciente(event.tickeadorId);
      emit(ActividadLoaded(logs: logs));
      // Mantener el vehículo seleccionado visible
      emit(VehicleFound(vehicle: event.vehicle));
    } catch (e) {
      emit(TickeadorError(message: e.toString()));
    }
  }

  /// Carga la actividad reciente del tickeador.
  Future<void> _onCargarActividad(
    CargarActividadEvent event,
    Emitter<TickeadorState> emit,
  ) async {
    emit(const TickeadorLoading());
    try {
      final logs = await _service.getActividadReciente(event.tickeadorId);
      emit(ActividadLoaded(logs: logs));
    } catch (e) {
      emit(TickeadorError(message: e.toString()));
    }
  }

  /// Valida un código QR de viaje.
  Future<void> _onValidateTripQr(
    ValidateTripQr event,
    Emitter<TickeadorState> emit,
  ) async {
    emit(const TickeadorLoading());
    try {
      final result = await _service.validateTripQR(event.qrCode);
      if (result['valid'] == true) {
        emit(QrValidated(
          message: 'Viaje válido',
          tripData: result,
        ));
      } else {
        emit(QrInvalid(message: result['error'] ?? 'Código QR inválido'));
      }
    } catch (e) {
      emit(TickeadorError(message: e.toString()));
    }
  }

  /// Carga el historial de verificaciones.
  Future<void> _onLoadVerificationHistory(
    LoadVerificationHistory event,
    Emitter<TickeadorState> emit,
  ) async {
    emit(const TickeadorLoading());
    try {
      // We need to get the uid from the auth state
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthLoaded) {
        final history = await _service.loadVerificationHistory(authState.user.uid);
        emit(VerificationHistoryLoaded(history: history));
      } else {
        emit(TickeadorError(message: 'Usuario no autenticado'));
      }
    } catch (e) {
      emit(TickeadorError(message: e.toString()));
    }
  }
}
