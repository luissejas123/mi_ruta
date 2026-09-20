import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:mi_ruta/core/utils/distance_utils.dart';

/// Base de datos SQLite local para rutas.
/// Almacena metadatos + bbox + polylines para búsqueda offline instantánea.
class RouteLocalDatabase {
  static const _dbName = 'mi_ruta_routes.db';
  static const _dbVersion = 4; // v4: agrega tabla stops_meta
  static const _tableRoutes = 'routes_meta';
  static const _tableConfig = 'app_config';
  static const _tableStops = 'stops_meta';

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Recrear tablas en cualquier upgrade para asegurar schema limpio
        await db.execute('DROP TABLE IF EXISTS $_tableRoutes');
        await db.execute('DROP TABLE IF EXISTS $_tableConfig');
        await _createTables(db);
        // stops_meta es nueva en v4: no dropear (no existia antes, y
        // _createTables ya usa CREATE TABLE IF NOT EXISTS para ella).
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableRoutes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        ref TEXT NOT NULL,
        color TEXT,
        direction_id TEXT,
        lat_min REAL NOT NULL,
        lat_max REAL NOT NULL,
        lng_min REAL NOT NULL,
        lng_max REAL NOT NULL,
        polyline_json TEXT,
        source TEXT DEFAULT 'gtfs'
      )
    ''');
    await db.execute('''
      CREATE TABLE $_tableConfig (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    // IF NOT EXISTS: en onUpgrade no se dropea (a diferencia de routes_meta/config)
    // para no perder cache de rutas en instalaciones que solo suman esta tabla.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableStops (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        route_refs TEXT
      )
    ''');
  }

  /// Inserta o reemplaza rutas en batch (incluye polyline_json).
  Future<void> upsertRoutes(List<Map<String, dynamic>> routes) async {
    final db = await _database;
    final batch = db.batch();
    for (final route in routes) {
      batch.insert(
        _tableRoutes,
        route,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Actualiza solo los campos bbox/meta desde Firestore, sin tocar polyline_json.
  /// Si la ruta no existe aún la inserta (con polyline_json = null).
  Future<void> upsertBboxOnly(List<Map<String, dynamic>> routes) async {
    final db = await _database;
    final batch = db.batch();
    for (final route in routes) {
      // Intenta insertar; si ya existe (mismo id) actualiza solo bbox y meta
      await db.rawInsert(
        '''
        INSERT INTO $_tableRoutes (id, name, ref, color, direction_id, lat_min, lat_max, lng_min, lng_max, source)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          ref = excluded.ref,
          color = excluded.color,
          lat_min = excluded.lat_min,
          lat_max = excluded.lat_max,
          lng_min = excluded.lng_min,
          lng_max = excluded.lng_max,
          source = excluded.source
        ''',
        [
          route['id'],
          route['name'] ?? '',
          route['ref'] ?? '',
          route['color'] ?? '',
          route['direction_id'],
          route['lat_min'],
          route['lat_max'],
          route['lng_min'],
          route['lng_max'],
          route['source'] ?? 'firestore',
        ],
      );
    }
  }

  /// Devuelve rutas cuyo bbox se SUPERPONE con el área [radiusDeg] alrededor
  /// del punto. Esto encuentra rutas que pasan cerca aunque el punto no esté
  /// exactamente dentro de su bbox.
  /// radiusDeg ≈ 0.018 → ~2 km en Cochabamba (lat ~-17°).
  Future<List<Map<String, dynamic>>> getRoutesInBbox(
    double lat,
    double lng, {
    double radiusDeg = 0.018,
  }) async {
    final db = await _database;
    return db.query(
      _tableRoutes,
      where: 'lat_min <= ? AND lat_max >= ? AND lng_min <= ? AND lng_max >= ?',
      whereArgs: [
        lat + radiusDeg,
        lat - radiusDeg,
        lng + radiusDeg,
        lng - radiusDeg,
      ],
    );
  }

  /// Rutas cuya polilínea pasa dentro de [radiusMeters] del punto
  /// [lat],[lng] — "qué trufis pasan cerca de mí". No usa `stops_meta`
  /// (no hay paradas reales sembradas hoy, ver `countStops`): en su lugar
  /// mide la intersección ruta↔radio contra las polylines GTFS ya
  /// sincronizadas. Pre-filtra por bbox (barato, mismo patrón que
  /// [getRoutesInBbox]) antes de decodificar polyline_json y medir la
  /// distancia real segmento a segmento. Devuelve las filas de
  /// `routes_meta` que califican, más una clave `distance_meters`,
  /// ordenadas de más cerca a más lejos.
  Future<List<Map<String, dynamic>>> getRoutesNearPoint(
    double lat,
    double lng, {
    required double radiusMeters,
  }) async {
    final radiusDeg = radiusMeters / 111000;
    final db = await _database;
    final candidates = await db.query(
      _tableRoutes,
      where: 'polyline_json IS NOT NULL AND '
          'lat_min <= ? AND lat_max >= ? AND lng_min <= ? AND lng_max >= ?',
      whereArgs: [
        lat + radiusDeg,
        lat - radiusDeg,
        lng + radiusDeg,
        lng - radiusDeg,
      ],
    );

    final origin = LatLng(lat, lng);
    final results = <Map<String, dynamic>>[];
    for (final row in candidates) {
      final polylineJson = row['polyline_json'] as String?;
      if (polylineJson == null) continue;
      final points = (jsonDecode(polylineJson) as List)
          .map((p) => LatLng(
                (p['lat'] as num).toDouble(),
                (p['lng'] as num).toDouble(),
              ))
          .toList();
      final distance = DistanceUtils.distanceToPolylineMeters(origin, points);
      if (distance <= radiusMeters) {
        results.add({...row, 'distance_meters': distance});
      }
    }
    results.sort((a, b) =>
        (a['distance_meters'] as double).compareTo(b['distance_meters'] as double));
    return results;
  }

  /// Guarda la polyline de una ruta en caché para uso offline.
  Future<void> cachePolyline(
    String routeId,
    List<Map<String, double>> polyline,
  ) async {
    final db = await _database;
    await db.update(
      _tableRoutes,
      {'polyline_json': jsonEncode(polyline)},
      where: 'id = ?',
      whereArgs: [routeId],
    );
  }

  /// Número de rutas almacenadas.
  Future<int> countRoutes() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_tableRoutes',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Número de rutas con polyline_json (listas para búsqueda).
  Future<int> countRoutesWithPolyline() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_tableRoutes WHERE polyline_json IS NOT NULL',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Devuelve un mapa {id → polyline_json} solo para rutas que tienen polyline.
  Future<Map<String, String>> getExistingPolylines() async {
    final db = await _database;
    final rows = await db.query(
      _tableRoutes,
      columns: ['id', 'polyline_json'],
      where: 'polyline_json IS NOT NULL',
    );
    return {
      for (final r in rows) r['id'] as String: r['polyline_json'] as String,
    };
  }

  /// Metadatos ligeros de todas las rutas sincronizadas, SIN polyline_json.
  /// Usar para listados (ej. panel Presidente) que no necesitan dibujar el mapa —
  /// evita cargar las polylines completas en memoria.
  Future<List<Map<String, dynamic>>> getAllRoutesMeta() async {
    final db = await _database;
    return db.query(
      _tableRoutes,
      columns: ['id', 'name', 'ref', 'color', 'direction_id'],
      orderBy: 'name ASC',
    );
  }

  // ── Paradas (stops) ───────────────────────────────────────────────────

  /// Inserta o reemplaza paradas en batch.
  Future<void> upsertStops(List<Map<String, dynamic>> stops) async {
    final db = await _database;
    final batch = db.batch();
    for (final stop in stops) {
      batch.insert(
        _tableStops,
        stop,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Numero de paradas almacenadas.
  Future<int> countStops() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_tableStops',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Paradas dentro de un rango cuadrado alrededor del punto dado.
  /// radiusDeg ~ 0.01 -> ~1.1 km en Cochabamba (lat ~-17°).
  Future<List<Map<String, dynamic>>> getStopsNearPoint(
    double lat,
    double lng, {
    double radiusDeg = 0.01,
  }) async {
    final db = await _database;
    return db.query(
      _tableStops,
      where: 'lat BETWEEN ? AND ? AND lng BETWEEN ? AND ?',
      whereArgs: [
        lat - radiusDeg,
        lat + radiusDeg,
        lng - radiusDeg,
        lng + radiusDeg,
      ],
    );
  }

  /// Obtiene metadatos de rutas por su ref (para enriquecer refs de parada
  /// con el nombre real de la linea, cuando exista en routes_meta).
  Future<List<Map<String, dynamic>>> getRoutesByRefs(List<String> refs) async {
    if (refs.isEmpty) return [];
    final db = await _database;
    final placeholders = List.filled(refs.length, '?').join(',');
    return db.query(
      _tableRoutes,
      distinct: true,
      columns: ['name', 'ref'],
      where: 'ref IN ($placeholders)',
      whereArgs: refs,
    );
  }

  /// Elimina todas las rutas (antes de re-sincronizar).
  Future<void> clearRoutes() async {
    final db = await _database;
    await db.delete(_tableRoutes);
  }

  // ── Config (clave/valor) ──────────────────────────────────────────────

  Future<String?> getConfig(String key) async {
    final db = await _database;
    final result = await db.query(
      _tableConfig,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return result.isEmpty ? null : result.first['value'] as String?;
  }

  Future<void> setConfig(String key, String value) async {
    final db = await _database;
    await db.insert(_tableConfig, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
