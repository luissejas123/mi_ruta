import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';

/// Datasource que carga rutas de Cochabamba desde asset JSON
/// Datos extraídos del GTFS oficial de la Trufi Association
class GtfsRoutesDatasource {
  // Cache en memoria para evitar recargar 18 MB en cada navegación
  static List<OsmRoute>? _cache;

  /// Limpia el cache (útil para pruebas)
  static void clearCache() => _cache = null;

  Future<List<OsmRoute>> fetchRoutes() async {
    if (_cache != null) return _cache!;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/cochabamba_routes.json',
      );
      final List<dynamic> routesList = json.decode(jsonString);

      final routes = <OsmRoute>[];
      for (final routeData in routesList) {
        final route = _parseRoute(routeData as Map<String, dynamic>);
        if (route != null) {
          routes.add(route);
        }
      }
      _cache = routes;
      return routes;
    } catch (e) {
      throw Exception('Error cargando rutas GTFS: $e');
    }
  }

  OsmRoute? _parseRoute(Map<String, dynamic> data) {
    try {
      final id = (data['id'] as num?)?.toInt() ?? 0;
      final name = (data['name'] as String?) ?? '';
      final ref = (data['ref'] as String?) ?? '';
      final segments = <List<LatLng>>[];

      final segmentsList = data['segments'] as List<dynamic>?;
      if (segmentsList != null) {
        for (final segment in segmentsList) {
          final pointsList =
              (segment as List<dynamic>?)?.map((p) {
                final point = p as List<dynamic>;
                return LatLng(
                  (point[0] as num).toDouble(),
                  (point[1] as num).toDouble(),
                );
              }).toList() ??
              [];
          if (pointsList.isNotEmpty) {
            segments.add(pointsList);
          }
        }
      }

      if (segments.isEmpty) return null;
      return OsmRoute(id: id, name: name, ref: ref, segments: segments);
    } catch (e) {
      return null;
    }
  }
}
