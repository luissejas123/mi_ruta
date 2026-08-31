import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Representa una ruta de trufi/micro extraída del GTFS de Cochabamba
class OsmRoute {
  final int id;
  final String name;
  final String ref;
  final String? directionId; // "0"=ida, "1"=vuelta
  final List<List<LatLng>> segments;

  OsmRoute({
    required this.id,
    required this.name,
    required this.ref,
    this.directionId,
    required this.segments,
  });

  /// Todos los puntos de la ruta (flatten de todos los segmentos)
  List<LatLng> get allPoints => segments.expand((s) => s).toList();

  /// Devuelve el nombre de la dirección (ej: "Ida", "Vuelta")
  String get directionName {
    // En el GTFS de Cochabamba: 0=Vuelta, 1=Ida
    return directionId == '1' ? 'Ida' : 'Vuelta';
  }

  /// Devuelve el nombre completo de la ruta incluyendo dirección
  String get displayName {
    final direction = directionId != null ? ' - ${directionName}' : '';
    return '$name$direction';
  }
}
