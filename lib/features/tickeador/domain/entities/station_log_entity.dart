import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Entidad que representa un registro de terminal en la colección `station_logs`.
///
/// Los campos corresponden exactamente a la estructura documentada:
/// tickeador_id, station_name, line_id, vehicle_plate, driver_id,
/// passenger_count, max_capacity, log_type, timestamp, time_since_last_departure.
class StationLogEntity extends Equatable {
  /// UID del tickeador que registró el log.
  final String tickeadorId;

  /// Nombre de la estación asignada.
  final String stationName;

  /// ID de la línea (se usa line_number del vehículo).
  final String lineId;

  /// Placa del vehículo (vehicle_id).
  final String vehiclePlate;

  /// UID del conductor (owner_uid del vehículo).
  final String driverId;

  /// Cantidad de pasajeros (no se inventa; se deja 0 si no hay fuente real).
  final int passengerCount;

  /// Capacidad máxima del vehículo.
  final int maxCapacity;

  /// Tipo de log: "departure" (salida) o "arrival" (llegada).
  final String logType;

  /// Timestamp del registro.
  final DateTime timestamp;

  /// Tiempo desde la última salida (no se inventa; se deja vacío si no hay fuente).
  final String timeSinceLastDeparture;

  const StationLogEntity({
    required this.tickeadorId,
    required this.stationName,
    required this.lineId,
    required this.vehiclePlate,
    required this.driverId,
    required this.passengerCount,
    required this.maxCapacity,
    required this.logType,
    required this.timestamp,
    required this.timeSinceLastDeparture,
  });

  /// Construye una entidad StationLog desde el documento de Firestore.
  factory StationLogEntity.fromJson(Map<String, dynamic> json) {
    return StationLogEntity(
      tickeadorId: json['tickeador_id'] as String? ?? '',
      stationName: json['station_name'] as String? ?? '',
      lineId: json['line_id'] as String? ?? '',
      vehiclePlate: json['vehicle_plate'] as String? ?? '',
      driverId: json['driver_id'] as String? ?? '',
      passengerCount: (json['passenger_count'] as num?)?.toInt() ?? 0,
      maxCapacity: (json['max_capacity'] as num?)?.toInt() ?? 0,
      logType: json['log_type'] as String? ?? '',
      timestamp:
          (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSinceLastDeparture:
          json['time_since_last_departure'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    tickeadorId,
    stationName,
    lineId,
    vehiclePlate,
    driverId,
    passengerCount,
    maxCapacity,
    logType,
    timestamp,
    timeSinceLastDeparture,
  ];
}
