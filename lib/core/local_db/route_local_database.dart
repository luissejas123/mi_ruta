import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Base de datos SQLite local para rutas.
/// Almacena metadatos + bbox + polylines para búsqueda offline instantánea.
class RouteLocalDatabase {
  static const _dbName = 'mi_ruta_routes.db';
  static const _dbVersion = 3; // Increment to rebuild with polyline_json
  static const _tableRoutes = 'routes_meta';
  static const _tableConfig = 'app_config';

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
