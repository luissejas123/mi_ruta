import 'package:equatable/equatable.dart';

abstract class VehicleReviewEvent extends Equatable {
  const VehicleReviewEvent();

  @override
  List<Object?> get props => [];
}

/// Carga las unidades con `status == 'pending_review'`.
class LoadVehicleReviewQueue extends VehicleReviewEvent {
  const LoadVehicleReviewQueue();
}

class ApproveVehicle extends VehicleReviewEvent {
  final String vehicleId;

  const ApproveVehicle(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

class RejectVehicle extends VehicleReviewEvent {
  final String vehicleId;

  const RejectVehicle(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}
