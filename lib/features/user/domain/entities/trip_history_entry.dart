import 'package:equatable/equatable.dart';

class TripHistoryEntry extends Equatable {
  final String id;
  final String userId;
  final String routeName;
  final String originName;
  final String destinationName;
  final Duration elapsed;
  final DateTime date;
  final double farePaid;
  // `ref` estable de cada ruta/tramo de bus del viaje (GTFS), para poder
  // consultar/filtrar por ruta de forma confiable — `routeName` es solo un
  // string de display ("Trufi 106") que no sirve como llave. Vacío en
  // entradas guardadas antes de este campo.
  final List<String> routeRefs;

  const TripHistoryEntry({
    required this.id,
    required this.userId,
    required this.routeName,
    required this.originName,
    required this.destinationName,
    required this.elapsed,
    required this.date,
    this.farePaid = 0.0,
    this.routeRefs = const [],
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    routeName,
    destinationName,
    elapsed,
    date,
    farePaid,
    routeRefs,
  ];
}
