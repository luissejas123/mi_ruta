import 'package:equatable/equatable.dart';

class VehicleEntity extends Equatable {
  final String vehicleId;
  final String ownerUid;
  final String lineNumber;
  final bool inService;
  final DateTime? serviceStartedAt;

  const VehicleEntity({
    required this.vehicleId,
    required this.ownerUid,
    required this.lineNumber,
    this.inService = false,
    this.serviceStartedAt,
  });

  @override
  List<Object?> get props => [
    vehicleId,
    ownerUid,
    lineNumber,
    inService,
    serviceStartedAt,
  ];
}