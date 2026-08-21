import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/vehicle_entity.dart';

/// Eventos de la feature Tickeador.
abstract class TickeadorEvent extends Equatable {
  const TickeadorEvent();

  @override
  List<Object?> get props => [];
}

/// Carga la información del tickeador (tickeador_info) desde Firestore.
class CargarTickeadorEvent extends TickeadorEvent {
  final String uid;

  const CargarTickeadorEvent({required this.uid});

  @override
  List<Object?> get props => [uid];
}

/// Busca un vehículo por placa.
class BuscarVehiculoEvent extends TickeadorEvent {
  final String placa;

  const BuscarVehiculoEvent({required this.placa});

  @override
  List<Object?> get props => [placa];
}

/// Marca la salida de un vehículo.
class MarcarSalidaEvent extends TickeadorEvent {
  final String tickeadorId;
  final String stationName;
  final VehicleEntity vehicle;

  const MarcarSalidaEvent({
    required this.tickeadorId,
    required this.stationName,
    required this.vehicle,
  });

  @override
  List<Object?> get props => [tickeadorId, stationName, vehicle];
}

/// Marca la llegada de un vehículo.
class MarcarLlegadaEvent extends TickeadorEvent {
  final String tickeadorId;
  final String stationName;
  final VehicleEntity vehicle;

  const MarcarLlegadaEvent({
    required this.tickeadorId,
    required this.stationName,
    required this.vehicle,
  });

  @override
  List<Object?> get props => [tickeadorId, stationName, vehicle];
}

/// Carga la actividad reciente del tickeador.
class CargarActividadEvent extends TickeadorEvent {
  final String tickeadorId;

  const CargarActividadEvent({required this.tickeadorId});

  @override
  List<Object?> get props => [tickeadorId];
}

/// Valida un código QR de viaje.
class ValidateTripQr extends TickeadorEvent {
  final String qrCode;

  const ValidateTripQr({required this.qrCode});

  @override
  List<Object?> get props => [qrCode];
}

/// Carga el historial de verificaciones.
class LoadVerificationHistory extends TickeadorEvent {
  const LoadVerificationHistory();

  @override
  List<Object?> get props => [];
}
