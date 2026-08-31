import 'package:equatable/equatable.dart';

/// Eventos del BLoC de la unidad del chofer.
abstract class DriverVehicleEvent extends Equatable {
  const DriverVehicleEvent();

  @override
  List<Object> get props => [];
}

/// Inicia el stream en tiempo real de la unidad asignada al chofer [ownerUid].
class StartMyVehicleStream extends DriverVehicleEvent {
  final String ownerUid;

  const StartMyVehicleStream({required this.ownerUid});

  @override
  List<Object> get props => [ownerUid];
}

/// TEMPORAL — modo prueba: carga una unidad fija en memoria, sin Firestore.
class LoadStaticDemoVehicle extends DriverVehicleEvent {
  const LoadStaticDemoVehicle();
}

/// Activa/desactiva "en servicio" para la unidad [vehicleId].
class ToggleOnDuty extends DriverVehicleEvent {
  final String vehicleId;
  final bool value;

  const ToggleOnDuty({required this.vehicleId, required this.value});

  @override
  List<Object> get props => [vehicleId, value];
}
