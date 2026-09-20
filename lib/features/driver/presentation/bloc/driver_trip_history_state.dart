import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_trip_entity.dart';

abstract class DriverTripHistoryState extends Equatable {
  const DriverTripHistoryState();

  @override
  List<Object?> get props => [];
}

class TripHistoryInitial extends DriverTripHistoryState {
  const TripHistoryInitial();
}

class TripHistoryLoading extends DriverTripHistoryState {
  const TripHistoryLoading();
}

class TripHistoryLoaded extends DriverTripHistoryState {
  final List<DriverTripEntity> trips;

  const TripHistoryLoaded({required this.trips});

  @override
  List<Object?> get props => [trips];
}

class TripHistoryError extends DriverTripHistoryState {
  final String message;

  const TripHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}