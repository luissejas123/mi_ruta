import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';

/// Unidad pendiente + datos del dueño, para no mostrar solo la placa.
class VehicleReviewEntry extends Equatable {
  final VehicleEntity vehicle;
  final String ownerName;
  final String ownerEmail;

  const VehicleReviewEntry({
    required this.vehicle,
    required this.ownerName,
    required this.ownerEmail,
  });

  @override
  List<Object?> get props => [vehicle, ownerName, ownerEmail];
}

abstract class VehicleReviewState extends Equatable {
  const VehicleReviewState();

  @override
  List<Object?> get props => [];
}

class VehicleReviewInitial extends VehicleReviewState {
  const VehicleReviewInitial();
}

class VehicleReviewLoading extends VehicleReviewState {
  const VehicleReviewLoading();
}

class VehicleReviewLoaded extends VehicleReviewState {
  final List<VehicleReviewEntry> pending;

  /// ID de la unidad con una escritura en curso, para el spinner de su fila.
  final String? updatingVehicleId;

  const VehicleReviewLoaded({required this.pending, this.updatingVehicleId});

  VehicleReviewLoaded copyWith({String? updatingVehicleId, bool clearUpdating = false}) {
    return VehicleReviewLoaded(
      pending: pending,
      updatingVehicleId: clearUpdating ? null : (updatingVehicleId ?? this.updatingVehicleId),
    );
  }

  bool get isEmpty => pending.isEmpty;

  @override
  List<Object?> get props => [pending, updatingVehicleId];
}

class VehicleReviewError extends VehicleReviewState {
  final String message;

  const VehicleReviewError(this.message);

  @override
  List<Object?> get props => [message];
}
