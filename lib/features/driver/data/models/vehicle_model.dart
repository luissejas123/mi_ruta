import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_legal_documents.dart';

/// Modelo de Unidad (Vehículo) - Capa de Data con Serialización JSON
class VehicleModel extends VehicleEntity {
  const VehicleModel({
    required super.vehicleId,
    required super.ownerUid,
    required super.vehicleType,
    required super.lineNumber,
    required super.internalNumber,
    required super.brand,
    required super.model,
    required super.color,
    required super.passengerCapacity,
    required super.status,
    required super.legalDocumentation,
    required super.isOnDuty,
    super.isOnDutyUpdatedAt,
    required super.updatedAt,
  });

  /// Convertir JSON de Firestore a VehicleModel. [docId] = id del documento (placa).
  factory VehicleModel.fromJson(Map<String, dynamic> json,
      {required String docId}) {
    final legalDocsJson =
        json['legal_documentation'] as Map<String, dynamic>? ?? {};
    return VehicleModel(
      vehicleId: json['vehicle_id'] as String? ?? docId,
      ownerUid: json['owner_uid'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String? ?? '',
      lineNumber: json['line_number'] as String? ?? '',
      internalNumber: json['internal_number'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      color: json['color'] as String? ?? '',
      passengerCapacity: json['passenger_capacity'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending_review',
      legalDocumentation:
          legalDocsJson.map((k, v) => MapEntry(k, v as String?)),
      isOnDuty: json['is_on_duty'] as bool? ?? false,
      isOnDutyUpdatedAt: json['is_on_duty_updated_at'] != null
          ? DateTime.tryParse(json['is_on_duty_updated_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Convertir VehicleModel a JSON para guardar en Firestore.
  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'owner_uid': ownerUid,
      'vehicle_type': vehicleType,
      'line_number': lineNumber,
      'internal_number': internalNumber,
      'brand': brand,
      'model': model,
      'color': color,
      'passenger_capacity': passengerCapacity,
      'status': status,
      'legal_documentation': legalDocumentation,
      'is_on_duty': isOnDuty,
      'is_on_duty_updated_at': isOnDutyUpdatedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Modelo de datos para la SOLICITUD de vehículo (RQ-68, "Convertirme en
/// chofer") — misma colección `vehicles` que [VehicleModel] (ver
/// FIRESTORE_COLLECTIONS_GUIDE.md) y mismos nombres de campo, pero mapeado
/// contra la entidad [Vehicle] (más simple, sin `isOnDuty`) que usa
/// `DriverRepository`. Separado de `VehicleModel` para no chocar de nombre
/// — ambos leen/escriben el mismo documento sin conflicto porque respetan
/// el mismo esquema de campos.
class VehicleApplicationModel extends Vehicle {
  const VehicleApplicationModel({
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
  factory VehicleApplicationModel.newApplication({
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
    return VehicleApplicationModel(
      // Normalizado igual que el flujo clásico (`registerVehicle`,
      // `DriverDatasource`) — antes esta solicitud guardaba la placa tal
      // cual la tecleó el chofer (sin mayúsculas), y `getVehicleByPlate`
      // (que sí normaliza al buscar) nunca la encontraba al abordar.
      id: plate.trim().toUpperCase(),
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

  factory VehicleApplicationModel.fromJson(String id, Map<String, dynamic> json) {
    final docs =
        (json['legal_documentation'] as Map?)?.cast<String, dynamic>() ?? {};
    return VehicleApplicationModel(
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
