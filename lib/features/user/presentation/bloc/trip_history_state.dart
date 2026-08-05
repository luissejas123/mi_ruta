import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/user/domain/entities/trip_history_entry.dart';

abstract class TripHistoryState extends Equatable {
  const TripHistoryState();
  @override
  List<Object?> get props => [];
}

class TripHistoryInitial extends TripHistoryState {}

class TripHistoryLoading extends TripHistoryState {}

class TripHistoryLoaded extends TripHistoryState {
  final List<TripHistoryEntry> trips;
  const TripHistoryLoaded(this.trips);
  @override
  List<Object?> get props => [trips];
}

class TripHistoryError extends TripHistoryState {
  final String message;
  const TripHistoryError(this.message);
  @override
  List<Object?> get props => [message];
}
