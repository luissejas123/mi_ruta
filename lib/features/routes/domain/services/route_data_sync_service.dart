import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mi_ruta/core/local_db/route_local_database.dart';
import 'package:mi_ruta/features/routes/data/datasources/gtfs_datasource.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

/// Servicio central de datos de rutas.
///
/// Estrategia:
/// 1. Primera apertura → parsea GTFS desde assets → guarda en SQLite (offline total)
/// 2. Cada apertura → verifica `config/routes_meta.version` en Firestore
///    Si hay versión nueva (admin actualizó rutas) → re-sincroniza desde Firestore
/// 3. Búsqueda → siempre desde SQLite (~1ms, sin red)
/// 4. Polylines faltantes → se descargan de Firestore y se cachean en SQLite
class RouteDataSyncService {
  final RouteLocalDatabase _localDb;
  final GtfsDatasource _gtfsDatasource;
  final FirebaseFirestore _firestore;

  /// Exposición pública para verificar estado de carga desde la UI
  RouteLocalDatabase get localDb => _localDb;

  static const _keyVersion = 'routes_version';
  static const _firestoreVersionDoc = 'config/routes_meta';
  final ValueNotifier<RouteSyncStatus> _syncStatus = ValueNotifier(
    RouteSyncStatus.idle,
  );
  Timer? _updatedMessageTimer;
  Future<void>? _initializationFuture;
  Future<void>? _versionCheckFuture;

  /// Estado observable para informar una actualización real de rutas.
  ValueListenable<RouteSyncStatus> get syncStatus => _syncStatus;

  RouteDataSyncService({
    required RouteLocalDatabase localDb,
    required GtfsDatasource gtfsDatasource,
    required FirebaseFirestore firestore,
  }) : _localDb = localDb,
       _gtfsDatasource = gtfsDatasource,
       _firestore = firestore;

  // ──────────────────────────────────────────────────────────────────────
  // Inicialización
  // ──────────────────────────────────────────────────────────────────────

  /// Punto de entrada principal. Llamar en initState antes de buscar rutas.
  /// - Si SQLite está vacío O no tiene polylines: parsea GTFS y puebla la BD.
  /// - Luego verifica si hay una versión más nueva en Firestore (en background).
  Future<void> ensureDataReady() {
    final pendingInitialization = _initializationFuture;
    if (pendingInitialization != null) return pendingInitialization;

    final initialization = _ensureDataReady().whenComplete(() {
      _initializationFuture = null;
    });
    _initializationFuture = initialization;
    return initialization;
  }

  Future<void> _ensureDataReady() async {
    final withPolyline = await _localDb.countRoutesWithPolyline();
    if (withPolyline == 0) {
      print(
        '🌱 SQLite sin polylines ($withPolyline) — re-sembrando desde GTFS...',
      );
      await _localDb.clearRoutes();
      await _seedFromGtfs();
    } else {
      print('✅ SQLite ya tiene $withPolyline rutas con polyline');
    }

    // Verificar actualización del admin panel en background (no bloquea la búsqueda)
    unawaited(_versionCheckFuture ??= _checkAndSyncVersion());
  }

  // ──────────────────────────────────────────────────────────────────────
  // Búsqueda geoespacial
  // ──────────────────────────────────────────────────────────────────────

  /// Busca rutas cuyo bbox contiene el punto. Siempre usa SQLite (instantáneo).
  /// NO descarga polylines de Firestore aquí — eso se hace solo cuando se selecciona una ruta.
  Future<List<RouteEntity>> getRoutesNearPoint({
    required double latitude,
    required double longitude,
  }) async {
    print('📍 Buscando en SQLite ($latitude, $longitude)...');
    final rows = await _localDb.getRoutesInBbox(latitude, longitude);
    print('📊 Coincidencias en SQLite: ${rows.length}');

    if (rows.isEmpty) return [];

    // Convertir SOLO las rutas que ya tienen polyline (del GTFS)
    // Las rutas sin polyline de Firestore se ignoran en búsquedas rápidas
    final routes = <RouteEntity>[];
    int withPolyline = 0;
    int withoutPolyline = 0;

    for (final row in rows) {
      final polylineJson = row['polyline_json'] as String?;
      if (polylineJson != null) {
        withPolyline++;
        routes.add(_rowToEntity(row));
      } else {
        withoutPolyline++;
      }
    }

    print(
      '  → $withPolyline rutas con polyline, $withoutPolyline sin (ignoradas)',
    );
    print('✅ ${routes.length} rutas con polyline encontradas');
    return routes;
  }

  // ──────────────────────────────────────────────────────────────────────
  // Seed inicial desde GTFS
  // ──────────────────────────────────────────────────────────────────────

  Future<void> _seedFromGtfs() async {
    print('🌱 Primera vez: cargando datos desde GTFS...');
    final routes = await _gtfsDatasource.parseRoutesForLocalDb();

    // Verificar que las rutas tienen polyline_json
    int routesWithPolyline = 0;
    for (final r in routes) {
      if (r['polyline_json'] != null) routesWithPolyline++;
    }
    print(
      '  → ${routes.length} rutas parseadas, $routesWithPolyline con polyline',
    );

    await _localDb.upsertRoutes(routes);
    await _localDb.setConfig(_keyVersion, 'gtfs_seed');
    print('✅ ${routes.length} rutas sembradas desde GTFS en SQLite');
  }

  // ──────────────────────────────────────────────────────────────────────
  // Sincronización con Firestore (para admin panel)
  // ──────────────────────────────────────────────────────────────────────

  Future<void> _checkAndSyncVersion() async {
    try {
      // Si no hay conexión, Source.server falla y se conserva el caché SQLite.
      final snap = await _firestore
          .doc(_firestoreVersionDoc)
          .get(const GetOptions(source: Source.server));
      if (!snap.exists) return; // Admin panel no configurado aún

      final firestoreVersion = snap.data()?['version']?.toString();
      if (firestoreVersion == null) return;

      final localVersion = await _localDb.getConfig(_keyVersion);
      if (localVersion == firestoreVersion) {
        print('✅ Datos de rutas al día (v$firestoreVersion)');
        return;
      }

      print(
        '🔄 Nueva versión detectada: $localVersion → $firestoreVersion. Sincronizando...',
      );
      _setSyncStatus(RouteSyncStatus.syncing);
      await _syncFromFirestore(firestoreVersion);
      _setSyncStatus(RouteSyncStatus.updated);
    } catch (e) {
      _setSyncStatus(RouteSyncStatus.idle);
      // No bloquear la app si hay problemas de red
      print('⚠️ No se pudo verificar versión de rutas: $e');
    }
  }

  /// Descarga la colección ligera `routes_bbox` de Firestore y actualiza SQLite.
  /// Solo actualiza bbox y metadatos; las polylines se descargan bajo demanda.
  Future<void> _syncFromFirestore(String version) async {
    print('📥 Sincronizando bbox desde Firestore (routes_bbox)...');
    final snap = await _firestore
        .collection('routes_bbox')
        .where('active', isEqualTo: true)
        .get(const GetOptions(source: Source.server));

    if (snap.docs.isEmpty) {
      print('⚠️ routes_bbox vacía en Firestore, cancelando sync');
      return;
    }

    final rows = snap.docs.map((doc) {
      final d = doc.data();
      return {
        'id': doc.id,
        'name': (d['name'] ?? '') as String,
        'ref': (d['ref'] ?? '') as String,
        'color': (d['color'] ?? '') as String,
        'direction_id': d['direction_id'] as String?,
        'lat_min': (d['lat_min'] as num).toDouble(),
        'lat_max': (d['lat_max'] as num).toDouble(),
        'lng_min': (d['lng_min'] as num).toDouble(),
        'lng_max': (d['lng_max'] as num).toDouble(),
        'source': 'firestore',
      };
    }).toList();

    // Upsert solo bbox — NO toca polyline_json de rutas ya cargadas por GTFS
    await _localDb.upsertBboxOnly(rows.cast<Map<String, dynamic>>());
    await _localDb.setConfig(_keyVersion, version);
    final withPoly = await _localDb.countRoutesWithPolyline();
    print(
      '✅ ${rows.length} rutas sincronizadas desde Firestore (v$version), $withPoly con polyline preservadas',
    );
  }

  void _setSyncStatus(RouteSyncStatus status) {
    _updatedMessageTimer?.cancel();
    _syncStatus.value = status;
    if (status == RouteSyncStatus.updated) {
      _updatedMessageTimer = Timer(const Duration(seconds: 2), () {
        _syncStatus.value = RouteSyncStatus.idle;
      });
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // Conversores
  // ──────────────────────────────────────────────────────────────────────

  RouteEntity _rowToEntity(Map<String, dynamic> row) {
    final polylineJson = row['polyline_json'] as String?;
    List<Map<String, double>>? polyline;
    if (polylineJson != null) {
      final raw = jsonDecode(polylineJson) as List;
      polyline = raw
          .map(
            (p) => {
              'lat': (p['lat'] as num).toDouble(),
              'lng': (p['lng'] as num).toDouble(),
            },
          )
          .toList();
    }

    return RouteEntity(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      ref: row['ref'] as String? ?? '',
      color: row['color'] as String?,
      directionId: row['direction_id'] as String?,
      polyline: polyline,
      latMin: row['lat_min'] as double?,
      latMax: row['lat_max'] as double?,
      lngMin: row['lng_min'] as double?,
      lngMax: row['lng_max'] as double?,
    );
  }

  RouteEntity _firestoreDocToEntity(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<Map<String, double>> stops = [];
    if (data['stops'] is List) {
      stops = (data['stops'] as List)
          .whereType<Map<String, dynamic>>()
          .map(
            (s) => {
              'lat': ((s['lat'] ?? 0.0) as num).toDouble(),
              'lng': ((s['lng'] ?? 0.0) as num).toDouble(),
            },
          )
          .toList();
    }

    List<Map<String, double>> polyline = [];
    if (data['polyline'] is List) {
      polyline = (data['polyline'] as List)
          .whereType<Map<String, dynamic>>()
          .map(
            (c) => {
              'lat': ((c['lat'] ?? 0.0) as num).toDouble(),
              'lng': ((c['lng'] ?? 0.0) as num).toDouble(),
            },
          )
          .toList();
    }

    return RouteEntity(
      id: doc.id,
      name: data['name'] ?? '',
      ref: data['ref'] ?? '',
      color: data['color'] as String?,
      directionId: data['direction_id'] as String?,
      stops: stops,
      polyline: polyline,
      latMin: (data['lat_min'] as num?)?.toDouble(),
      latMax: (data['lat_max'] as num?)?.toDouble(),
      lngMin: (data['lng_min'] as num?)?.toDouble(),
      lngMax: (data['lng_max'] as num?)?.toDouble(),
    );
  }
}

enum RouteSyncStatus { idle, syncing, updated }
