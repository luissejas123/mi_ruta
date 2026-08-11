import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Accede al servicio de geocodificación inversa del dispositivo:
/// convierte coordenadas en una dirección legible.
class GeocodingDatasource {
  /// Devuelve la dirección aproximada de [position], o null si no se pudo
  /// resolver (sin conexión, fuera de cobertura, etc.).
  Future<String?> reverseGeocode(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final addr = [
        p.street,
        p.subLocality,
        p.locality,
      ].where((s) => s != null && s.isNotEmpty).join(', ');
      return addr.isEmpty ? 'Ubicación desconocida' : addr;
    } catch (_) {
      return null;
    }
  }
}
