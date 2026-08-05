import 'dart:convert';

import 'package:flutter/services.dart';

/// Parsea los archivos GTFS bundleados en assets y devuelve datos de rutas
/// listos para insertar en SQLite.
///
/// Archivos usados:
///   - assets/cochabamba_gtfs/routes.txt  → nombre y ref de cada ruta
///   - assets/cochabamba_gtfs/trips.txt   → relación ruta ↔ shape
///   - assets/cochabamba_gtfs/shapes.txt  → coordenadas de cada shape
class GtfsDatasource {
  static const _base = 'assets/cochabamba_gtfs';

  /// Parsea GTFS y devuelve lista de maps listos para SQLite.
  /// Cada map tiene: id, name, ref, color, lat_min/max, lng_min/max,
  /// polyline_json, source.
  Future<List<Map<String, dynamic>>> parseRoutesForLocalDb() async {
    print('📂 Parseando GTFS desde assets...');

    try {
      // Cargar los 3 archivos CSV desde assets
      final routesCsv = await rootBundle.loadString('$_base/routes.txt');
      final tripsCsv = await rootBundle.loadString('$_base/trips.txt');
      final shapesCsv = await rootBundle.loadString('$_base/shapes.txt');

      print('  ✓ Archivos cargados desde assets');

      // Parsear directamente aquí (sin isolate para mejor debugging)
      return _parseGtfsSync(routesCsv, tripsCsv, shapesCsv);
    } catch (e, st) {
      print('❌ Error parseando GTFS: $e\n$st');
      return [];
    }
  }

  /// Parsea GTFS de forma sincrónica
  List<Map<String, dynamic>> _parseGtfsSync(
    String routesCsv,
    String tripsCsv,
    String shapesCsv,
  ) {
    // ── 1. routes.txt
    final routesRows = _parseCSV(routesCsv);
    final routeMeta = <String, Map<String, String>>{};
    for (final row in routesRows) {
      final id = row['route_id'] ?? '';
      if (id.isEmpty) continue;
      routeMeta[id] = {
        'name': row['route_long_name'] ?? '',
        'ref': row['route_short_name'] ?? '',
        'color': row['route_color'] ?? '',
      };
    }
    print('  ✓ ${routeMeta.length} rutas en routes.txt');

    // ── 2. trips.txt
    final tripsRows = _parseCSV(tripsCsv);
    final routeShapes = <String, Map<String, Set<String>>>{};
    for (final row in tripsRows) {
      final routeId = row['route_id'] ?? '';
      final shapeId = row['shape_id'] ?? '';
      final directionId = row['direction_id'] ?? '0';
      if (routeId.isEmpty || shapeId.isEmpty) continue;
      routeShapes
          .putIfAbsent(routeId, () => {})
          .putIfAbsent(directionId, () => <String>{})
          .add(shapeId);
    }
    print('  ✓ ${routeShapes.length} rutas en trips.txt');

    // ── 3. shapes.txt
    final shapesRows = _parseCSV(shapesCsv);
    final shapePointsRaw = <String, List<_Pt>>{};
    for (final row in shapesRows) {
      final shapeId = row['shape_id'] ?? '';
      if (shapeId.isEmpty) continue;
      final lat = double.tryParse(row['shape_pt_lat'] ?? '');
      final lng = double.tryParse(row['shape_pt_lon'] ?? '');
      final seq = int.tryParse(row['shape_pt_sequence'] ?? '');
      if (lat == null || lng == null || seq == null) continue;
      shapePointsRaw.putIfAbsent(shapeId, () => []).add(_Pt(lat, lng, seq));
    }

    for (final pts in shapePointsRaw.values) {
      pts.sort((a, b) => a.seq.compareTo(b.seq));
    }
    print('  ✓ ${shapePointsRaw.length} shapes en shapes.txt');

    // ── 4. Ensamblar rutas por dirección
    const margin = 0.001;
    final result = <Map<String, dynamic>>[];

    for (final routeId in routeMeta.keys) {
      final meta = routeMeta[routeId]!;
      final directionMap = routeShapes[routeId];
      if (directionMap == null || directionMap.isEmpty) continue;

      for (final directionEntry in directionMap.entries) {
        final directionId = directionEntry.key;
        final shapes = directionEntry.value;
        if (shapes.isEmpty) continue;

        String? bestShapeId;
        int bestCount = 0;
        for (final shapeId in shapes) {
          final pts = shapePointsRaw[shapeId];
          if (pts != null && pts.length > bestCount) {
            bestCount = pts.length;
            bestShapeId = shapeId;
          }
        }
        if (bestShapeId == null) continue;
        final canonicalPts = shapePointsRaw[bestShapeId]!;

        double? latMin, latMax, lngMin, lngMax;
        final allPoints = <Map<String, double>>[];

        for (final p in canonicalPts) {
          if (latMin == null || p.lat < latMin) latMin = p.lat;
          if (latMax == null || p.lat > latMax) latMax = p.lat;
          if (lngMin == null || p.lng < lngMin) lngMin = p.lng;
          if (lngMax == null || p.lng > lngMax) lngMax = p.lng;
          allPoints.add({'lat': p.lat, 'lng': p.lng});
        }

        if (latMin == null || allPoints.isEmpty) continue;

        final routeIdWithDir = 'gtfs_${routeId}_dir${directionId}';

        result.add({
          'id': routeIdWithDir,
          'name': meta['name'],
          'ref': meta['ref'],
          'color': meta['color'],
          'direction_id': directionId,
          'lat_min': latMin - margin,
          'lat_max': latMax! + margin,
          'lng_min': lngMin! - margin,
          'lng_max': lngMax! + margin,
          'polyline_json': jsonEncode(allPoints),
          'source': 'gtfs',
        });
      }
    }

    print('✅ GTFS parseado: ${result.length} rutas con polylines');
    return result;
  }

  /// Parsea CSV desde un string
  List<Map<String, String>> _parseCSV(String csvContent) {
    final lines = const LineSplitter().convert(csvContent);
    if (lines.isEmpty) return [];

    final headers = lines[0].split(',').map((h) => h.trim()).toList();
    final rows = <Map<String, String>>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final values = line.split(',');
      final row = <String, String>{};

      for (int j = 0; j < headers.length && j < values.length; j++) {
        row[headers[j]] = values[j].trim();
      }
      rows.add(row);
    }

    return rows;
  }
}

/// Punto de un shape GTFS (latitud, longitud, secuencia)
class _Pt {
  final double lat, lng;
  final int seq;
  const _Pt(this.lat, this.lng, this.seq);
}
