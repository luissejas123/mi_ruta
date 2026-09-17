import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_shift.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';

abstract class DriverVehicleState extends Equatable {
  const DriverVehicleState();

  @override
  List<Object?> get props => [];
}

class DriverVehicleInitial extends DriverVehicleState {
  const DriverVehicleInitial();
}

class DriverVehicleLoading extends DriverVehicleState {
  const DriverVehicleLoading();
}

/// [vehicle] es null cuando el chofer aún no tiene ninguna unidad asignada.
/// [toggleError] es un mensaje transitorio (no persiste en Firestore): se
/// llena si falló el último intento de cambiar "en servicio" (p. ej. sin
/// conexión), para avisar sin perder la tarjeta de la unidad ya cargada.
/// [lastClosedShift] (RQ-82) es transitorio también: se llena solo cuando
/// se acaba de cerrar una jornada, para que la UI muestre el resumen.
class DriverVehicleLoaded extends DriverVehicleState {
  final VehicleEntity? vehicle;
  final String? toggleError;
  final DriverShiftEntity? lastClosedShift;

  const DriverVehicleLoaded({
    required this.vehicle,
    this.toggleError,
    this.lastClosedShift,
  });

  @override
  List<Object?> get props => [vehicle, toggleError, lastClosedShift];
}

class DriverVehicleError extends DriverVehicleState {
  final String message;

  const DriverVehicleError({required this.message});

  @override
  List<Object?> get props => [message];
}
