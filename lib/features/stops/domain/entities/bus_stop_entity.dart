import 'package:equatable/equatable.dart';

class BusStopEntity extends Equatable {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final List<String> routeRefs;

  const BusStopEntity({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.routeRefs,
  });

  @override
  List<Object?> get props => [id, name, lat, lng, routeRefs];
}
