/// Posición en vivo de una unidad en servicio (mapa en tiempo real).
class LiveVehicleLocation {
  final String vehicleId;
  final String driverId;
  final String? routeRef;
  final String? routeName;
  final double latitude;
  final double longitude;

  /// Rumbo en grados (0 = norte), si el GPS lo informa.
  final double? heading;
  final DateTime updatedAt;

  const LiveVehicleLocation({
    required this.vehicleId,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    this.routeRef,
    this.routeName,
    this.heading,
  });

  /// Una posición sin actualizar hace más de [maxAge] se considera vieja
  /// (el chofer cerró la app o perdió señal) y no se muestra en el mapa.
  bool isFresh(DateTime now, {Duration maxAge = const Duration(minutes: 2)}) =>
      now.difference(updatedAt) <= maxAge;
}
