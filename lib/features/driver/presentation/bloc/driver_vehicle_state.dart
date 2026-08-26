import 'package:equatable/equatable.dart';
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
class DriverVehicleLoaded extends DriverVehicleState {
  final VehicleEntity? vehicle;

  const DriverVehicleLoaded({required this.vehicle});

  @override
  List<Object?> get props => [vehicle];
}

class DriverVehicleError extends DriverVehicleState {
  final String message;

  const DriverVehicleError({required this.message});

  @override
  List<Object?> get props => [message];
}
