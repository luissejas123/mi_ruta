import 'package:equatable/equatable.dart';

class TickeadorOperation extends Equatable {
  final String id;
  final String tickeadorId;
  final String stationName;
  final String lineId;
  final String vehiclePlate;
  final String driverId;
  final int passengerCount;
  final int maxCapacity;
  final String logType;
  final DateTime timestamp;
  final int? timeSinceLastDeparture;

  const TickeadorOperation({
    required this.id,
    required this.tickeadorId,
    required this.stationName,
    required this.lineId,
    required this.vehiclePlate,
    required this.driverId,
    required this.passengerCount,
    required this.maxCapacity,
    required this.logType,
    required this.timestamp,
    this.timeSinceLastDeparture,
  });

  bool get isDeparture => logType == 'departure';

  @override
  List<Object?> get props => [
    id,
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
