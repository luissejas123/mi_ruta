import 'package:equatable/equatable.dart';

<<<<<<< HEAD
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
=======
/// Entidad de dominio para una unidad de transporte (vehículo).
class VehicleEntity extends Equatable {
  final String vehicleId; // doc id = placa
  final String ownerUid; // uid del chofer dueño-operador
>>>>>>> origin/adolfo-dev
  final String vehicleType;
  final String lineNumber;
  final String internalNumber;
  final String brand;
  final String model;
  final String color;
  final int passengerCapacity;
<<<<<<< HEAD
  final VehicleStatus status;
  final bool inService;
  final DateTime? serviceStartedAt;
  // legal_documentation: URLs a Storage (FIRESTORE_COLLECTIONS_GUIDE.md)
  final String? soatUrl;
  final String? vehicleInspectionUrl;
  final String? driverLicenseUrl;
  final String? municipalOperationCardUrl;
  final String? ruatUrl;
=======
  final String status; // approved / pending_review / rejected
  final Map<String, String?> legalDocumentation;
  final bool isOnDuty;
  final DateTime? isOnDutyUpdatedAt;
  final DateTime updatedAt;
>>>>>>> origin/adolfo-dev

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
<<<<<<< HEAD
    required this.inService,
    this.serviceStartedAt,
    this.soatUrl,
    this.vehicleInspectionUrl,
    this.driverLicenseUrl,
    this.municipalOperationCardUrl,
    this.ruatUrl,
  });

  VehicleEntity copyWith({
    bool? inService,
    DateTime? serviceStartedAt,
    bool clearServiceStartedAt = false,
    String? internalNumber,
    String? brand,
    String? model,
    String? color,
    String? soatUrl,
    String? vehicleInspectionUrl,
    String? driverLicenseUrl,
    String? municipalOperationCardUrl,
    String? ruatUrl,
  }) {
    return VehicleEntity(
      vehicleId: vehicleId,
      ownerUid: ownerUid,
      vehicleType: vehicleType,
      lineNumber: lineNumber,
      internalNumber: internalNumber ?? this.internalNumber,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      color: color ?? this.color,
      passengerCapacity: passengerCapacity,
      status: status,
      inService: inService ?? this.inService,
      serviceStartedAt: clearServiceStartedAt
          ? null
          : (serviceStartedAt ?? this.serviceStartedAt),
      soatUrl: soatUrl ?? this.soatUrl,
      vehicleInspectionUrl: vehicleInspectionUrl ?? this.vehicleInspectionUrl,
      driverLicenseUrl: driverLicenseUrl ?? this.driverLicenseUrl,
      municipalOperationCardUrl:
          municipalOperationCardUrl ?? this.municipalOperationCardUrl,
      ruatUrl: ruatUrl ?? this.ruatUrl,
    );
  }
=======
    required this.legalDocumentation,
    required this.isOnDuty,
    this.isOnDutyUpdatedAt,
    required this.updatedAt,
  });

  bool get isApproved => status == 'approved';
>>>>>>> origin/adolfo-dev

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
<<<<<<< HEAD
        inService,
        serviceStartedAt,
        soatUrl,
        vehicleInspectionUrl,
        driverLicenseUrl,
        municipalOperationCardUrl,
        ruatUrl,
=======
        legalDocumentation,
        isOnDuty,
        isOnDutyUpdatedAt,
        updatedAt,
>>>>>>> origin/adolfo-dev
      ];
}
