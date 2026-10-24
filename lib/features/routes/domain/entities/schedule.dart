import 'package:equatable/equatable.dart';

class Schedule extends Equatable {
  final String id;

  /// Identificador del viaje GTFS
  final String tripId;

  /// Identificador de la ruta GTFS
  final String routeId;

  /// Identificador de la parada GTFS
  final String stopId;

  /// Dirección de recorrido GTFS (0 ida / 1 vuelta)
  final String? directionId;

  /// Hora programada de llegada
  final String arrivalTime;

  /// Hora programada de salida
  final String departureTime;

  /// Identificador del servicio GTFS (calendar.txt)
  final String? serviceId;

  const Schedule({
    required this.id,
    required this.tripId,
    required this.routeId,
    required this.stopId,
    this.directionId,
    required this.arrivalTime,
    required this.departureTime,
    this.serviceId,
  });

  @override
  List<Object?> get props => [
        id,
        tripId,
        routeId,
        stopId,
        directionId,
        arrivalTime,
        departureTime,
        serviceId,
      ];
}