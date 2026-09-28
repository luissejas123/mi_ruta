import 'package:equatable/equatable.dart';

abstract class TransportedPassengersEvent extends Equatable {
  const TransportedPassengersEvent();

  @override
  List<Object?> get props => [];
}

/// Carga las rutas disponibles (GTFS) para el selector de ruta.
class LoadRoutesForQueryEvent extends TransportedPassengersEvent {
  const LoadRoutesForQueryEvent();
}

class SearchTransportedPassengersEvent extends TransportedPassengersEvent {
  final String routeRef;
  final DateTime from;
  final DateTime to;

  const SearchTransportedPassengersEvent({
    required this.routeRef,
    required this.from,
    required this.to,
  });

  @override
  List<Object?> get props => [routeRef, from, to];
}
