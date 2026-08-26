import 'package:equatable/equatable.dart';

abstract class NearbyStopsEvent extends Equatable {
  const NearbyStopsEvent();
  @override
  List<Object?> get props => [];
}

class LoadNearbyStops extends NearbyStopsEvent {
  final double lat;
  final double lng;
  const LoadNearbyStops(this.lat, this.lng);
  @override
  List<Object?> get props => [lat, lng];
}
