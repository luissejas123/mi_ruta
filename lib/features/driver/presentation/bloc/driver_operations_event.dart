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

/// Ya no lleva nombre de parada — la UI valida proximidad GPS real contra
/// el polyline de la ruta antes de disparar este evento (ver
/// `DriverService.notifyStop`, docs/PLAN_SEGURIDAD_TARIFAS_GPS.md Bloque 1).
class NotifyStop extends DriverOperationsEvent {
  const NotifyStop();
}

class TripPaymentReceived extends DriverOperationsEvent {
  final String tripId;
  final double amount;
  final String? passengerId;

  const TripPaymentReceived(this.tripId, this.amount, {this.passengerId});

  @override
  List<Object?> get props => [tripId, amount, passengerId];
}

/// Cambió la cantidad de pasajeros abordados sin bajar/pagar todavía —
/// viene del stream de `DriverService.streamBoardedCount`.
class BoardedCountUpdated extends DriverOperationsEvent {
  final int count;

  const BoardedCountUpdated(this.count);

  @override
  List<Object?> get props => [count];
}
