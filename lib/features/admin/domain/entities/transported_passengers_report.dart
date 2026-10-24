import 'package:equatable/equatable.dart';

/// Viajes de la ruta consultada en un día calendario del rango. Incluye
/// días con 0 viajes (no se saltan huecos) para que el gráfico quede
/// continuo.
class DailyTripsCount extends Equatable {
  final DateTime day;
  final int count;

  const DailyTripsCount({required this.day, required this.count});

  @override
  List<Object?> get props => [day, count];
}

/// Resultado de la consulta "pasajeros transportados" para una ruta y un
/// rango de fechas: cuenta viajes registrados en `trip_history/*/trips`
/// (historial del pasajero) cuyo `route_refs` incluye la ruta consultada.
class TransportedPassengersReport extends Equatable {
  final String routeRef;
  final DateTime from;
  final DateTime to;
  final int totalTrips;
  final int uniquePassengers;
  // Desglose día a día del mismo resultado — para mostrarlo como gráfico,
  // sin hacer una segunda consulta a Firestore.
  final List<DailyTripsCount> tripsPerDay;

  const TransportedPassengersReport({
    required this.routeRef,
    required this.from,
    required this.to,
    required this.totalTrips,
    required this.uniquePassengers,
    required this.tripsPerDay,
  });

  @override
  List<Object?> get props => [
    routeRef,
    from,
    to,
    totalTrips,
    uniquePassengers,
    tripsPerDay,
  ];
}
