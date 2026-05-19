import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Representa una ruta de trufi/micro extraída del GTFS de Cochabamba
class OsmRoute {
  final int id;
  final String name;
  final String ref;
  final List<List<LatLng>> segments;

  OsmRoute({
    required this.id,
    required this.name,
    required this.ref,
    required this.segments,
  });

  /// Todos los puntos de la ruta (flatten de todos los segmentos)
  List<LatLng> get allPoints => segments.expand((s) => s).toList();
}
