import 'package:equatable/equatable.dart';

/// Entidad que representa un vehículo registrado en la colección `vehicles`.
///
/// Los campos corresponden exactamente a la estructura documentada:
/// vehicle_id (placa), owner_uid, vehicle_type, line_number, internal_number,
/// brand, model, color, passenger_capacity, status, updated_at.
class VehicleEntity extends Equatable {
  /// Placa del vehículo (vehicle_id).
  final String vehicleId;

  /// UID del conductor propietario.
  final String ownerUid;

  /// Tipo de vehículo (bus, micro, taxitrufi, minibus).
  final String vehicleType;

  /// Número de línea.
  final String lineNumber;

  /// Número interno.
  final String internalNumber;

  /// Marca.
  final String brand;

  /// Modelo.
  final String model;

  /// Color.
  final String color;

  /// Capacidad de pasajeros.
  final int passengerCapacity;

  /// Estado (pending_review, approved, rejected, maintenance).
  final String status;

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
  });

  /// Construye una entidad Vehicle desde el documento de Firestore.
  factory VehicleEntity.fromJson(Map<String, dynamic> json) {
    return VehicleEntity(
      vehicleId: json['vehicle_id'] as String? ?? '',
      ownerUid: json['owner_uid'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String? ?? '',
      lineNumber: json['line_number'] as String? ?? '',
      internalNumber: json['internal_number'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      color: json['color'] as String? ?? '',
      passengerCapacity: (json['passenger_capacity'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
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
  ];
}
