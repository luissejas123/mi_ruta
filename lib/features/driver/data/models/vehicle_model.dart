import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_legal_documents.dart';

/// Modelo de datos para la colección `vehicles` (ver
/// FIRESTORE_COLLECTIONS_GUIDE.md) — mapea exactamente los campos ya
/// documentados, sin agregar ninguno nuevo.
class VehicleModel extends Vehicle {
  const VehicleModel({
    required super.id,
    required super.ownerUid,
    required super.vehicleType,
    required super.lineNumber,
    required super.internalNumber,
    required super.brand,
    required super.model,
    required super.color,
    required super.passengerCapacity,
    required super.status,
    required super.legalDocuments,
    required super.updatedAt,
  });

  /// Construye una solicitud nueva (aún no guardada) — status inicial
  /// 'pending_review', igual que benefit_requests al crearse.
  factory VehicleModel.newApplication({
    required String plate,
    required String ownerUid,
    required String vehicleType,
    required String lineNumber,
    required String internalNumber,
    required String brand,
    required String model,
    required String color,
    required int passengerCapacity,
    required VehicleLegalDocuments legalDocuments,
  }) {
    return VehicleModel(
      id: plate,
      ownerUid: ownerUid,
      vehicleType: vehicleType,
      lineNumber: lineNumber,
      internalNumber: internalNumber,
      brand: brand,
      model: model,
      color: color,
      passengerCapacity: passengerCapacity,
      status: 'pending_review',
      legalDocuments: legalDocuments,
      updatedAt: DateTime.now(),
    );
  }

  factory VehicleModel.fromJson(String id, Map<String, dynamic> json) {
    final docs =
        (json['legal_documentation'] as Map?)?.cast<String, dynamic>() ?? {};
    return VehicleModel(
      id: id,
      ownerUid: json['owner_uid'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String? ?? '',
      lineNumber: json['line_number'] as String? ?? '',
      internalNumber: json['internal_number'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      color: json['color'] as String? ?? '',
      passengerCapacity: (json['passenger_capacity'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending_review',
      legalDocuments: VehicleLegalDocuments(
        soatUrl: docs['soat_url'] as String? ?? '',
        vehicleInspectionUrl: docs['vehicle_inspection_url'] as String? ?? '',
        driverLicenseUrl: docs['driver_license_url'] as String? ?? '',
        municipalOperationCardUrl:
            docs['municipal_operation_card_url'] as String? ?? '',
        ruatUrl: docs['ruat_url'] as String? ?? '',
      ),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  /// No incluye `updated_at` — el datasource lo fija con
  /// `FieldValue.serverTimestamp()` al escribir.
  Map<String, dynamic> toJson() => {
        'vehicle_id': id,
        'owner_uid': ownerUid,
        'vehicle_type': vehicleType,
        'line_number': lineNumber,
        'internal_number': internalNumber,
        'brand': brand,
        'model': model,
        'color': color,
        'passenger_capacity': passengerCapacity,
        'status': status,
        'legal_documentation': {
          'soat_url': legalDocuments.soatUrl,
          'vehicle_inspection_url': legalDocuments.vehicleInspectionUrl,
          'driver_license_url': legalDocuments.driverLicenseUrl,
          'municipal_operation_card_url':
              legalDocuments.municipalOperationCardUrl,
          'ruat_url': legalDocuments.ruatUrl,
        },
      };

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
