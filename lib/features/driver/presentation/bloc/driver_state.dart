import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle.dart';

abstract class DriverState extends Equatable {
  const DriverState();
  @override
  List<Object?> get props => [];
}

class DriverInitial extends DriverState {}

class DriverLoading extends DriverState {}

/// El usuario nunca solicitó convertirse en chofer.
class NoVehicleApplication extends DriverState {}

class VehicleApplicationLoaded extends DriverState {
  final Vehicle vehicle;
  const VehicleApplicationLoaded(this.vehicle);
  @override
  List<Object?> get props => [vehicle];
}

class DriverModeActivated extends DriverState {}

class DriverModeDeactivated extends DriverState {}

class DriverError extends DriverState {
  final String message;
  const DriverError(this.message);
  @override
  List<Object?> get props => [message];
}
