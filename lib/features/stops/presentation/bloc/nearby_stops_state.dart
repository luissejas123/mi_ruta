import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/stops/domain/entities/bus_stop_entity.dart';

abstract class NearbyStopsState extends Equatable {
  const NearbyStopsState();
  @override
  List<Object?> get props => [];
}

class NearbyStopsInitial extends NearbyStopsState {}

class NearbyStopsLoading extends NearbyStopsState {}

class NearbyStopsLoaded extends NearbyStopsState {
  final List<BusStopEntity> stops;
  final double originLat;
  final double originLng;
  const NearbyStopsLoaded(this.stops, this.originLat, this.originLng);
  @override
  List<Object?> get props => [stops, originLat, originLng];
}

class NearbyStopsError extends NearbyStopsState {
  final String message;
  const NearbyStopsError(this.message);
  @override
  List<Object?> get props => [message];
}
