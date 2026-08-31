import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';

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
