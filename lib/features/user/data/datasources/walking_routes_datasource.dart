import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Acceso a la Routes API de Google para calcular trayectos a pie.
class WalkingRoutesDatasource {
  String get _apiKey => dotenv.env['MAPS_API_KEY'] ?? '';

  /// Devuelve la lista de puntos de la ruta a pie de [from] a [to].
  /// Usa Google Routes API si hay API key; si no, cae en OSRM (gratuito).
  Future<List<LatLng>> fetchRoute(LatLng from, LatLng to) async {
    if (_apiKey.isNotEmpty) {
      final result = await _fetchGoogleRoute(from, to);
      if (result != null) return result;
    }
    // Fallback: OSRM routing engine (sin API key, gratuito)
    return _fetchOsrmRoute(from, to);
  }

  /// Google Routes API
  Future<List<LatLng>?> _fetchGoogleRoute(LatLng from, LatLng to) async {
    final uri = Uri.parse(
      'https://routes.googleapis.com/directions/v2:computeRoutes',
    );

    try {
      debugPrint('[WalkingRoutes] Llamando Routes API...');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
        },
        body: jsonEncode({
          'origin': {
            'location': {
              'latLng': {
                'latitude': from.latitude,
                'longitude': from.longitude,
              },
            },
          },
          'destination': {
            'location': {
              'latLng': {'latitude': to.latitude, 'longitude': to.longitude},
            },
          },
          'travelMode': 'WALK',
        }),
      );

      debugPrint('[WalkingRoutes] HTTP ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('[WalkingRoutes] Google error: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final encodedPolyline =
          routes[0]['polyline']['encodedPolyline'] as String;
      final decoded = _decodePolyline(encodedPolyline);
      debugPrint('[WalkingRoutes] Google puntos: ${decoded.length}');
      return decoded.isEmpty ? null : decoded;
    } catch (e) {
      debugPrint('[WalkingRoutes] Google error: $e');
      return null;
    }
  }

  /// OSRM routing (gratuito, sin API key, respeta calles)
  static Future<List<LatLng>> _fetchOsrmRoute(LatLng from, LatLng to) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/foot/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=polyline',
    );
    try {
      debugPrint('[WalkingRoutes] Llamando OSRM...');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [from, to];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return [from, to];

      final encodedPolyline = routes[0]['geometry'] as String;
      final decoded = _decodePolyline(encodedPolyline);
      debugPrint('[WalkingRoutes] OSRM puntos: ${decoded.length}');
      return decoded.isEmpty ? [from, to] : decoded;
    } catch (e) {
      debugPrint('[WalkingRoutes] OSRM error: $e');
      return [from, to];
    }
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final result = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, raw = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        raw |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (raw & 1) != 0 ? ~(raw >> 1) : (raw >> 1);
      shift = 0;
      raw = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        raw |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (raw & 1) != 0 ? ~(raw >> 1) : (raw >> 1);
      result.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return result;
  }
}
