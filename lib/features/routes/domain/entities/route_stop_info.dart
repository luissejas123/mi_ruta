import 'package:equatable/equatable.dart';

class RouteStopInfo extends Equatable {
  final String stopName;
  final List<String> routeLines;
  final String distance;
  final String trafficStatus;
  final String status;
  final String estimatedArrival;

  const RouteStopInfo({
    required this.stopName,
    required this.routeLines,
    required this.distance,
    required this.trafficStatus,
    required this.status,
    required this.estimatedArrival,
  });

  @override
  List<Object?> get props => [
    stopName,
    routeLines,
    distance,
    trafficStatus,
    status,
    estimatedArrival,
  ];
}
