import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/station_log_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/tickeador_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/vehicle_entity.dart';

/// Estado base de la feature Tickeador.
abstract class TickeadorState extends Equatable {
  const TickeadorState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial.
class TickeadorInitial extends TickeadorState {
  const TickeadorInitial();
}

/// Cargando la información del tickeador, vehículo o actividad.
class TickeadorLoading extends TickeadorState {
  const TickeadorLoading();
}

/// Información del tickeador cargada correctamente.
class TickeadorLoaded extends TickeadorState {
  final TickeadorEntity? tickeador;

  const TickeadorLoaded({this.tickeador});

  @override
  List<Object?> get props => [tickeador];
}

/// Vehículo encontrado por placa.
class VehicleFound extends TickeadorState {
  final VehicleEntity vehicle;

  const VehicleFound({required this.vehicle});

  @override
  List<Object?> get props => [vehicle];
}

/// Vehículo no encontrado.
class VehicleNotFound extends TickeadorState {
  const VehicleNotFound();
}

/// Operación (marcar salida/llegada) exitosa.
class StationLogSuccess extends TickeadorState {
  final String message;

  const StationLogSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Actividad reciente cargada.
class ActividadLoaded extends TickeadorState {
  final List<StationLogEntity> logs;

  const ActividadLoaded({required this.logs});

  @override
  List<Object?> get props => [logs];
}

/// Error en cualquier operación.
class TickeadorError extends TickeadorState {
  final String message;

  const TickeadorError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Historial de verificaciones cargado.
class VerificationHistoryLoaded extends TickeadorState {
  final List<dynamic> history;

  const VerificationHistoryLoaded({required this.history});

  @override
  List<Object?> get props => [history];
}

/// QR válido.
class QrValidated extends TickeadorState {
  final String message;
  final dynamic tripData;

  const QrValidated({required this.message, required this.tripData});

  @override
  List<Object?> get props => [message, tripData];
}

/// QR inválido.
class QrInvalid extends TickeadorState {
  final String message;

  const QrInvalid({required this.message});

  @override
  List<Object?> get props => [message];
}
