import 'package:equatable/equatable.dart';

abstract class NearbyStopsEvent extends Equatable {
  const NearbyStopsEvent();
  @override
  List<Object?> get props => [];
}

class LoadNearbyStops extends NearbyStopsEvent {
  final double lat;
  final double lng;
  /// Radio de búsqueda en metros. Default 500m (antes fijo en ~1.1km, sin
  /// forma de configurarlo desde la UI).
  final double radiusMeters;
  const LoadNearbyStops(this.lat, this.lng, {this.radiusMeters = 500});
  @override
  List<Object?> get props => [lat, lng, radiusMeters];
}
