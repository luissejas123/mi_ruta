import 'package:equatable/equatable.dart';

abstract class TickeadorOperationsEvent extends Equatable {
  const TickeadorOperationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTickeadorOperations extends TickeadorOperationsEvent {
  final String tickeadorId;

  const LoadTickeadorOperations(this.tickeadorId);

  @override
  List<Object?> get props => [tickeadorId];
}

class RegisterTickeadorOperation extends TickeadorOperationsEvent {
  final String tickeadorId;
  final String stationName;
  final String lineId;
  final String logType;
  final String vehiclePlate;
  final String driverId;
  final int passengerCount;
  final int maxCapacity;

  const RegisterTickeadorOperation({
    required this.tickeadorId,
    required this.stationName,
    required this.lineId,
    required this.logType,
    this.vehiclePlate = '',
    this.driverId = '',
    this.passengerCount = 0,
    this.maxCapacity = 0,
  });

  @override
  List<Object?> get props => [
    tickeadorId,
    stationName,
    lineId,
    logType,
    vehiclePlate,
    driverId,
    passengerCount,
    maxCapacity,
  ];
}
