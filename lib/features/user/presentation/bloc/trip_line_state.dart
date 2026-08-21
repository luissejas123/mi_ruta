import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripSegmentData {
  final LatLng boardingStop;
  final LatLng alightingStop;
  final List<LatLng> transitPoints;

  TripSegmentData({
    required this.boardingStop,
    required this.alightingStop,
    required this.transitPoints,
  });
}

class WalkingPaths {
  final List<LatLng> startWalkPath;
  final List<LatLng> endWalkPath;

  WalkingPaths({required this.startWalkPath, required this.endWalkPath});
}

abstract class TripLineState extends Equatable {
  const TripLineState();

  @override
  List<Object?> get props => [];
}

class TripLineInitial extends TripLineState {
  const TripLineInitial();
}

class TripLineLoading extends TripLineState {
  const TripLineLoading();
}

class TripLineLoaded extends TripLineState {
  final TripSegmentData tripSegment;
  final WalkingPaths walkingPaths;

  const TripLineLoaded({required this.tripSegment, required this.walkingPaths});

  @override
  List<Object?> get props => [tripSegment, walkingPaths];
}

class TripLineError extends TripLineState {
  final String message;

  const TripLineError({required this.message});

  @override
  List<Object?> get props => [message];
}
