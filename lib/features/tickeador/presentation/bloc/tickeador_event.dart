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

/// Marca el paso de un vehículo por un punto intermedio del camino.
class MarcarIntermedioEvent extends TickeadorEvent {
  final String tickeadorId;
  final String stationName;
  final VehicleEntity vehicle;

  const MarcarIntermedioEvent({
    required this.tickeadorId,
    required this.stationName,
    required this.vehicle,
  });

  @override
  List<Object?> get props => [tickeadorId, stationName, vehicle];
}

/// Busca un vehículo por su `vehicleId` exacto tras escanear el QR fijo de
/// unidad (`ownerUid|vehicleId`, ver `UnitQrPage`) — a diferencia de
/// [BuscarVehiculoEvent] (búsqueda manual por placa tipeada), emite
/// [VehicleFoundViaQr] para que la UI abra directo el selector de acción
/// (Salida/Llegada/Intermedio) en vez de solo llenar la tarjeta de vehículo.
class BuscarVehiculoPorQrEvent extends TickeadorEvent {
  final String vehicleId;

  const BuscarVehiculoPorQrEvent({required this.vehicleId});

  @override
  List<Object?> get props => [vehicleId];
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
  final String tickeadorUid;

  const ValidateTripQr({required this.qrCode, required this.tickeadorUid});

  @override
  List<Object?> get props => [qrCode, tickeadorUid];
}

/// Carga el historial de verificaciones.
class LoadVerificationHistory extends TickeadorEvent {
  final String? uid;

  const LoadVerificationHistory({this.uid});

  @override
  List<Object?> get props => [uid];
}
