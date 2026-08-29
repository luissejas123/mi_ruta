import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';

abstract class DriverServiceState extends Equatable {
  const DriverServiceState();

  @override
  List<Object?> get props => [];
}

class DriverServiceLoading extends DriverServiceState {
  const DriverServiceLoading();
}

/// El chofer autenticado no tiene ninguna unidad asignada (owner_uid).
class DriverServiceNoVehicle extends DriverServiceState {
  const DriverServiceNoVehicle();
}

class DriverServiceLoaded extends DriverServiceState {
  final VehicleEntity vehicle;
  final bool isUpdating;

  const DriverServiceLoaded(this.vehicle, {this.isUpdating = false});

  @override
  List<Object?> get props => [vehicle, isUpdating];
}

class DriverServiceError extends DriverServiceState {
  final String message;
  final VehicleEntity? vehicle;

  const DriverServiceError(this.message, {this.vehicle});

  @override
  List<Object?> get props => [message, vehicle];
}
