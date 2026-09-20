import 'package:equatable/equatable.dart';

abstract class NearbyRoutesEvent extends Equatable {
  const NearbyRoutesEvent();
  @override
  List<Object?> get props => [];
}

class LoadNearbyRoutes extends NearbyRoutesEvent {
  final double lat;
  final double lng;
  /// Radio de búsqueda en metros (250/500 desde la UI).
  final double radiusMeters;
  const LoadNearbyRoutes(this.lat, this.lng, {this.radiusMeters = 500});
  @override
  List<Object?> get props => [lat, lng, radiusMeters];
}
