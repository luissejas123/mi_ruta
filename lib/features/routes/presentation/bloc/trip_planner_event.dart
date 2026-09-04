import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/routes/domain/entities/planned_trip.dart';

abstract class TripPlannerEvent extends Equatable {
  const TripPlannerEvent();
  @override
  List<Object?> get props => [];
}

class SearchTripOptions extends TripPlannerEvent {
  final String userId;
  final LatLng origin;
  final LatLng destination;
  final String originName;
  final String destinationName;
  final DateTime scheduledAt;

  const SearchTripOptions({
    required this.userId,
    required this.origin,
    required this.destination,
    required this.originName,
    required this.destinationName,
    required this.scheduledAt,
  });

  @override
  List<Object?> get props => [
    userId,
    origin,
    destination,
    originName,
    destinationName,
    scheduledAt,
  ];
}

class SaveTripPlan extends TripPlannerEvent {
  final PlannedTrip trip;
  const SaveTripPlan(this.trip);
  @override
  List<Object?> get props => [trip];
}

class LoadMyPlans extends TripPlannerEvent {
  final String userId;
  const LoadMyPlans(this.userId);
  @override
  List<Object?> get props => [userId];
}

class DeleteTripPlan extends TripPlannerEvent {
  final String userId;
  final String tripId;
  const DeleteTripPlan(this.userId, this.tripId);
  @override
  List<Object?> get props => [userId, tripId];
}

class MarkTripCompleted extends TripPlannerEvent {
  final String userId;
  final String tripId;
  const MarkTripCompleted(this.userId, this.tripId);
  @override
  List<Object?> get props => [userId, tripId];
}

class LoadCancelledTrips extends TripPlannerEvent {
  final String userId;
  const LoadCancelledTrips(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ClearSearch extends TripPlannerEvent {
  const ClearSearch();
}
