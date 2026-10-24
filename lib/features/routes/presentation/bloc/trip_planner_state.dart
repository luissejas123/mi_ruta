import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/routes/domain/entities/planned_trip.dart';

abstract class TripPlannerState extends Equatable {
  const TripPlannerState();
  @override
  List<Object?> get props => [];
}

class TripPlannerInitial extends TripPlannerState {}

class TripPlannerLoading extends TripPlannerState {}

class TripSearchResults extends TripPlannerState {
  final List<PlannedTrip> options;
  const TripSearchResults(this.options);
  @override
  List<Object?> get props => [options];
}

class TripSearchEmpty extends TripPlannerState {}

class MyPlansLoaded extends TripPlannerState {
  final List<PlannedTrip> plans;
  const MyPlansLoaded(this.plans);
  @override
  List<Object?> get props => [plans];
}

class CancelledTripsLoaded extends TripPlannerState {
  final List<PlannedTrip> trips;
  const CancelledTripsLoaded(this.trips);
  @override
  List<Object?> get props => [trips];
}

class TripPlanSaved extends TripPlannerState {
  final PlannedTrip trip;
  const TripPlanSaved(this.trip);
  @override
  List<Object?> get props => [trip];
}

class TripPlannerError extends TripPlannerState {
  final String message;
  const TripPlannerError(this.message);
  @override
  List<Object?> get props => [message];
}
