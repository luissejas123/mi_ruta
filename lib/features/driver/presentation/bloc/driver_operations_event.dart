import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';

abstract class DriverOperationsEvent extends Equatable {
  const DriverOperationsEvent();

  @override
  List<Object?> get props => [];
}

/// Carga ruta asignada, historial e ingresos del chofer para su unidad.
class LoadDriverOperations extends DriverOperationsEvent {
  final VehicleEntity vehicle;

  const LoadDriverOperations(this.vehicle);

  @override
  List<Object?> get props => [vehicle];
}

class GenerateTripCharge extends DriverOperationsEvent {
  final double amount;

  const GenerateTripCharge(this.amount);

  @override
  List<Object?> get props => [amount];
}

class ClearTripCharge extends DriverOperationsEvent {
  const ClearTripCharge();
}

class UpdateVehicleInfo extends DriverOperationsEvent {
  final String brand;
  final String model;
  final String color;
  final String internalNumber;

  const UpdateVehicleInfo({
    required this.brand,
    required this.model,
    required this.color,
    required this.internalNumber,
  });

  @override
  List<Object?> get props => [brand, model, color, internalNumber];
}

class DownloadTripHistory extends DriverOperationsEvent {
  final String driverName;

  const DownloadTripHistory(this.driverName);

  @override
  List<Object?> get props => [driverName];
}

class NotifyStop extends DriverOperationsEvent {
  final String stopName;

  const NotifyStop(this.stopName);

  @override
  List<Object?> get props => [stopName];
}

class TripPaymentReceived extends DriverOperationsEvent {
  final String tripId;
  final double amount;

  const TripPaymentReceived(this.tripId, this.amount);

  @override
  List<Object?> get props => [tripId, amount];
}
