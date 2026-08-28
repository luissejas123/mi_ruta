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

  /// Parsea stops.txt y devuelve lista de maps listos para SQLite.
  /// Cada map tiene: id, name, lat, lng, route_refs (JSON de List<String>).
  Future<List<Map<String, dynamic>>> parseStopsForLocalDb() async {
    print('📂 Parseando paradas GTFS desde assets...');
    try {
      final stopsCsv = await rootBundle.loadString('$_base/stops.txt');
      // stops.txt trae campos citados con comas dentro (ej. nombres de
      // avenidas con coma), a diferencia de routes/trips/shapes — usa un
      // parser que respeta comillas en vez de _parseCSV (split naive).
      final rows = _parseQuotedCSV(stopsCsv);

      final result = <Map<String, dynamic>>[];
      for (final row in rows) {
        final id = row['stop_id'] ?? '';
        final name = row['stop_name'] ?? '';
        final lat = double.tryParse(row['stop_lat'] ?? '');
        final lng = double.tryParse(row['stop_lon'] ?? '');
        if (id.isEmpty || name.isEmpty || lat == null || lng == null) {
          continue;
        }

        result.add({
          'id': id,
          'name': name,
          'lat': lat,
          'lng': lng,
          'route_refs': jsonEncode(_parseStopDescRefs(row['stop_desc'])),
        });
      }

      print('✅ ${result.length} paradas parseadas desde stops.txt');
      return result;
    } catch (e, st) {
      print('❌ Error parseando paradas GTFS: $e\n$st');
      return [];
    }
  }

  /// Extrae los refs de línea de un stop_desc con formato "23(0-1-108-...)".
  List<String> _parseStopDescRefs(String? desc) {
    if (desc == null) return [];
    final match = RegExp(r'\(([^)]*)\)').firstMatch(desc);
    if (match == null) return [];
    final inner = match.group(1) ?? '';
    if (inner.isEmpty) return [];
    return inner.split('-').where((r) => r.isNotEmpty).toList();
  }

  /// Parsea CSV respetando campos citados con comas dentro (RFC4180 simple).
  List<Map<String, String>> _parseQuotedCSV(String csvContent) {
    final lines = const LineSplitter().convert(csvContent);
    if (lines.isEmpty) return [];

    final headers = _splitCsvLine(lines[0]).map((h) => h.trim()).toList();
    final rows = <Map<String, String>>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final values = _splitCsvLine(line);
      final row = <String, String>{};
      for (int j = 0; j < headers.length && j < values.length; j++) {
        row[headers[j]] = values[j].trim();
      }
      rows.add(row);
    }

    return rows;
  }

  /// Divide una linea CSV por comas, ignorando comas dentro de campos
  /// citados con comillas dobles (ej. "Av. X, esq. Y").
  List<String> _splitCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        values.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    values.add(buffer.toString());
    return values;
  }

  // ── Horarios GTFS (usados por GtfsScheduleService) ──────────────────────
  // Devuelven las filas "crudas" del CSV (claves = columnas GTFS), sin
  // transformar a formato SQLite — a diferencia de parseRoutesForLocalDb/
  // parseStopsForLocalDb, que sí preparan datos para insertar en la BD local.

  /// Filas crudas de `stops.txt` (stop_id, stop_name, stop_lat, stop_lon...).
  Future<List<Map<String, String>>> parseStops() async {
    final csv = await rootBundle.loadString('$_base/stops.txt');
    return _parseQuotedCSV(csv);
  }

  /// Filas crudas de `stop_times.txt` (trip_id, stop_id, arrival_time...).
  Future<List<Map<String, String>>> parseStopTimes() async {
    final csv = await rootBundle.loadString('$_base/stop_times.txt');
    return _parseCSV(csv);
  }

  /// Filas crudas de `trips.txt` (trip_id, route_id, service_id...).
  Future<List<Map<String, String>>> parseTrips() async {
    final csv = await rootBundle.loadString('$_base/trips.txt');
    return _parseCSV(csv);
  }

  /// Filas crudas de `frequencies.txt` (trip_id, start_time, end_time, headway_secs).
  Future<List<Map<String, String>>> parseFrequencies() async {
    final csv = await rootBundle.loadString('$_base/frequencies.txt');
    return _parseCSV(csv);
  }

  /// Filas crudas de `calendar.txt` (service_id, monday..sunday).
  Future<List<Map<String, String>>> parseCalendar() async {
    final csv = await rootBundle.loadString('$_base/calendar.txt');
    return _parseCSV(csv);
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
