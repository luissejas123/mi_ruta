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
  bool get isPendingReview => status == 'pending_review';
  bool get isRejected => status == 'rejected';

  VehicleEntity copyWith({
    String? vehicleId,
    String? ownerUid,
    String? vehicleType,
    String? lineNumber,
    String? internalNumber,
    String? brand,
    String? model,
    String? color,
    int? passengerCapacity,
    String? status,
    Map<String, String?>? legalDocumentation,
    bool? isOnDuty,
    DateTime? isOnDutyUpdatedAt,
    DateTime? updatedAt,
  }) {
    return VehicleEntity(
      vehicleId: vehicleId ?? this.vehicleId,
      ownerUid: ownerUid ?? this.ownerUid,
      vehicleType: vehicleType ?? this.vehicleType,
      lineNumber: lineNumber ?? this.lineNumber,
      internalNumber: internalNumber ?? this.internalNumber,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      color: color ?? this.color,
      passengerCapacity: passengerCapacity ?? this.passengerCapacity,
      status: status ?? this.status,
      legalDocumentation: legalDocumentation ?? this.legalDocumentation,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      isOnDutyUpdatedAt: isOnDutyUpdatedAt ?? this.isOnDutyUpdatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
        legalDocumentation,
        isOnDuty,
        isOnDutyUpdatedAt,
        updatedAt,
      ];
}
