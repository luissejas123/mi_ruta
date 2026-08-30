import 'dart:convert';

import 'package:mi_ruta/features/admin/data/datasources/admin_route_datasource.dart';
import 'package:mi_ruta/features/routes/data/datasources/gtfs_datasource.dart';
import 'package:mi_ruta/features/routes/data/datasources/route_datasource.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

/// Datasource de gestión administrativa de rutas.
///
/// Reutiliza [RouteDatasource] (CRUD en la colección real `routes` de
/// Firestore) y [GtfsDatasource] (parseo del GTFS bundleado en assets).
class AdminRouteDataSourceImpl implements AdminRouteDataSource {
  final RouteDatasource _routeDatasource;
  final GtfsDatasource _gtfsDatasource;

  AdminRouteDataSourceImpl({
    required RouteDatasource routeDatasource,
    required GtfsDatasource gtfsDatasource,
  })  : _routeDatasource = routeDatasource,
        _gtfsDatasource = gtfsDatasource;

  @override
  Future<List<RouteEntity>> getRoutes() async {
    // Ligero (routes_bbox, sin polyline): la lista solo muestra nombre/ref/
    // color. Cargar el polyline completo de ~280 rutas acá era lo que
    // crasheaba "Gestión de rutas" (OOM en dispositivo real).
    return await _routeDatasource.getAllRoutesLight();
  }

  @override
  Future<RouteEntity> getRouteById(String routeId) async {
    final route = await _routeDatasource.getRouteById(routeId);
    if (route == null) {
      throw Exception('Ruta no encontrada');
    }
    return route;
  }

  @override
  Future<String> createRoute({
    required String name,
    required String ref,
    String? color,
    String? description,
    List<Map<String, double>>? stops,
    List<Map<String, double>>? polyline,
  }) async {
    return await _routeDatasource.createRoute(
      name: name,
      ref: ref,
      color: color,
      stops: stops,
      polyline: polyline,
      description: description,
    );
  }

  @override
  Future<void> updateRoute({
    required String routeId,
    String? name,
    String? ref,
    String? color,
    String? description,
    bool? active,
  }) async {
    await _routeDatasource.updateRoute(
      routeId: routeId,
      name: name,
      ref: ref,
      color: color,
      description: description,
      active: active,
    );
  }

  @override
  Future<void> deleteRoute(String routeId) async {
    await _routeDatasource.deleteRoute(routeId);
  }

  @override
  Future<int> loadRoutesFromGtfs() async {
    final parsed = await _gtfsDatasource.parseRoutesForLocalDb();
    if (parsed.isEmpty) {
      throw Exception('No se pudieron parsear las rutas GTFS');
    }

    int successCount = 0;
    for (final routeData in parsed) {
      try {
        final polylineJson = routeData['polyline_json'] as String?;
        List<Map<String, double>> polyline = [];
        if (polylineJson != null) {
          final decoded = jsonDecode(polylineJson);
          if (decoded is List) {
            polyline = decoded
                .whereType<Map<String, dynamic>>()
                .map(
                  (p) => Map<String, double>.from({
                    'lat': (p['lat'] ?? 0.0).toDouble(),
                    'lng': (p['lng'] ?? 0.0).toDouble(),
                  }),
                )
                .toList();
          }
        }

        // upsert por ref+direction_id (no .add()): antes, presionar "Cargar
        // rutas desde GTFS" dos veces duplicaba las ~280 rutas cada vez.
        await _routeDatasource.upsertRouteByRef(
          name: routeData['name'] as String? ?? 'Ruta sin nombre',
          ref: routeData['ref'] as String? ?? '',
          directionId: routeData['direction_id'] as String?,
          color: routeData['color'] as String?,
          polyline: polyline,
          description: 'Cargada desde GTFS',
        );
        successCount++;
      } catch (e) {
        // Una ruta fallida no detiene la carga del resto.
        continue;
      }
    }

    return successCount;
  }
}
