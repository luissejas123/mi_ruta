import 'package:equatable/equatable.dart';

/// Entidad de dominio para una unidad de transporte (vehículo).
class VehicleEntity extends Equatable {
  final String vehicleId; // doc id = placa
  final String ownerUid; // uid del chofer dueño-operador
  final String vehicleType;
  final String lineNumber;
  final String internalNumber;
  final String brand;
  final String model;
  final String color;
  final int passengerCapacity;
  final String status; // approved / pending_review / rejected
  final Map<String, String?> legalDocumentation;
  final bool isOnDuty;
  final DateTime? isOnDutyUpdatedAt;
  final DateTime updatedAt;

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
    required this.legalDocumentation,
    required this.isOnDuty,
    this.isOnDutyUpdatedAt,
    required this.updatedAt,
  });

  bool get isApproved => status == 'approved';

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
        legalDocumentation,
        isOnDuty,
        isOnDutyUpdatedAt,
        updatedAt,
      ];
}
