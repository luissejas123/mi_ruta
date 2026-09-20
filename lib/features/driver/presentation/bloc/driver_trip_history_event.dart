import 'package:equatable/equatable.dart';

abstract class DriverTripHistoryEvent extends Equatable {
  const DriverTripHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Carga el historial de viajes del conductor.
class LoadTripHistory extends DriverTripHistoryEvent {
  final String driverId;

  const LoadTripHistory(this.driverId);

  @override
  List<Object?> get props => [driverId];
}