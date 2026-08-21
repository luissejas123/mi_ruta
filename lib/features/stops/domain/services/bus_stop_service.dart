import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/local_db/route_local_database.dart';
import 'package:mi_ruta/core/utils/distance_utils.dart';
import 'package:mi_ruta/features/stops/domain/entities/bus_stop_entity.dart';

class BusStopService {
  final RouteLocalDatabase _localDb;

  BusStopService({required RouteLocalDatabase localDb}) : _localDb = localDb;

  /// Paradas mas cercanas a [lat],[lng], ordenadas por distancia real
  /// (Haversine), limitadas a [maxResults].
  Future<List<BusStopEntity>> getNearbyStops(
    double lat,
    double lng, {
    int maxResults = 30,
  }) async {
    final rows = await _localDb.getStopsNearPoint(lat, lng);
    final origin = LatLng(lat, lng);

    final stops = rows.map(_rowToEntity).toList();
    stops.sort((a, b) {
      final distA = DistanceUtils.metersApprox(origin, LatLng(a.lat, a.lng));
      final distB = DistanceUtils.metersApprox(origin, LatLng(b.lat, b.lng));
      return distA.compareTo(distB);
    });

    return stops.take(maxResults).toList();
  }

  /// Distancia formateada ("250 m" / "1.3 km") de [stop] al punto dado.
  String distanceLabel(BusStopEntity stop, double lat, double lng) {
    final meters = DistanceUtils.metersApprox(
      LatLng(lat, lng),
      LatLng(stop.lat, stop.lng),
    );
    return DistanceUtils.formatMeters(meters);
  }

  /// Mapea cada ref a su nombre real de linea cuando existe en routes_meta;
  /// si no se encuentra, deja el nombre vacio (la UI cae al ref solo).
  Future<Map<String, String>> enrichRouteRefs(List<String> refs) async {
    final rows = await _localDb.getRoutesByRefs(refs);
    return {
      for (final r in rows)
        (r['ref'] as String): (r['name'] as String? ?? ''),
    };
  }

  BusStopEntity _rowToEntity(Map<String, dynamic> row) {
    final refsJson = row['route_refs'] as String?;
    final refs = refsJson != null
        ? (jsonDecode(refsJson) as List).cast<String>()
        : <String>[];
    return BusStopEntity(
      id: row['id'] as String,
      name: row['name'] as String,
      lat: row['lat'] as double,
      lng: row['lng'] as double,
      routeRefs: refs,
    );
  }
}
