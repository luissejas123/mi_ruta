import 'package:equatable/equatable.dart';

enum VehicleStatus { approved, pendingReview, rejected }

VehicleStatus vehicleStatusFromString(String value) {
  switch (value) {
    case 'approved':
      return VehicleStatus.approved;
    case 'rejected':
      return VehicleStatus.rejected;
    default:
      return VehicleStatus.pendingReview;
  }
}

/// Unidad de transporte (vehículo) asignada a un chofer.
/// Corresponde a la colección `vehicles` documentada en
/// FIRESTORE_COLLECTIONS_GUIDE.md (owner_uid = uid del chofer).
class VehicleEntity extends Equatable {
  final String vehicleId;
  final String ownerUid;
  final String vehicleType;
  final String lineNumber;
  final String internalNumber;
  final String brand;
  final String model;
  final String color;
  final int passengerCapacity;
  final VehicleStatus status;
  final bool inService;
  final DateTime? serviceStartedAt;

  const VehicleEntity({
    required this.vehicleId,
    required this.ownerUid,
    required this.vehicleType,
    required this.lineNumber,
    required this.internalNumber,
    required this.brand,
    required this.model,
    required this.color,
    required this.passengerCapacity,
    required this.status,
    required this.inService,
    this.serviceStartedAt,
  });

  VehicleEntity copyWith({
    bool? inService,
    DateTime? serviceStartedAt,
    bool clearServiceStartedAt = false,
  }) {
    return VehicleEntity(
      vehicleId: vehicleId,
      ownerUid: ownerUid,
      vehicleType: vehicleType,
      lineNumber: lineNumber,
      internalNumber: internalNumber,
      brand: brand,
      model: model,
      color: color,
      passengerCapacity: passengerCapacity,
      status: status,
      inService: inService ?? this.inService,
      serviceStartedAt: clearServiceStartedAt
          ? null
          : (serviceStartedAt ?? this.serviceStartedAt),
    );
  }

  @override
  List<Object?> get props => [
        vehicleId,
        ownerUid,
        vehicleType,
        lineNumber,
        internalNumber,
        brand,
        model,
        color,
        passengerCapacity,
        status,
        inService,
        serviceStartedAt,
      ];
}
