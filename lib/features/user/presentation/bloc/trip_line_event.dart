import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';

abstract class TripLineEvent extends Equatable {
  const TripLineEvent();

  @override
  List<Object?> get props => [];
}

class TripLineInitialized extends TripLineEvent {
  final OsmRoute route;
  final PlaceResult destination;
  final LatLng? origin;

  const TripLineInitialized({
    required this.route,
    required this.destination,
    this.origin,
  });

  @override
  List<Object?> get props => [route, destination, origin];
}

class TripLineNavigationRequested extends TripLineEvent {
  const TripLineNavigationRequested();
}
