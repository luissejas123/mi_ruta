import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

/// Gestor de caché local para rutas
/// Descarga todas las rutas de Firestore UNA SOLA VEZ y las guarda localmente
class RouteCacheManager {
  static const String _cacheFileName = 'routes_cache_v2.json';
  static const Duration _cacheExpiration = Duration(days: 1);

  /// Guarda rutas en caché local
  static Future<void> saveRoutesToCache(List<RouteEntity> routes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_cacheFileName');

      // Convertir a JSON
      final json = jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'routes': routes
            .map(
              (r) => {
                'id': r.id,
                'name': r.name,
                'ref': r.ref,
                'color': r.color,
                'polyline': r.polyline,
                'stops': r.stops,
                'description': r.description,
                'active': r.active,
              },
            )
            .toList(),
      });

      await file.writeAsString(json);
      print('✅ Rutas guardadas en caché local');
    } catch (e) {
      print('❌ Error guardando rutas en caché: $e');
    }
  }

  /// Carga rutas desde caché local
  static Future<List<RouteEntity>> loadRoutesFromCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_cacheFileName');

      if (!file.existsSync()) {
        return [];
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Verificar expiración
      final timestamp = DateTime.parse(json['timestamp'] as String);
      if (DateTime.now().difference(timestamp) > _cacheExpiration) {
        print('⚠️ Caché expirado');
        return [];
      }

      // Parsear rutas
      final routesList = (json['routes'] as List).cast<Map<String, dynamic>>();
      final routes = routesList.map((r) => _parseRoute(r)).toList();

      print('✅ ${routes.length} rutas cargadas desde caché local');
      return routes;
    } catch (e) {
      print('❌ Error cargando rutas del caché: $e');
      return [];
    }
  }

  /// Limpia el caché
  static Future<void> clearCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_cacheFileName');
      if (file.existsSync()) {
        await file.delete();
        print('✅ Caché limpiado');
      }
    } catch (e) {
      print('❌ Error limpiando caché: $e');
    }
  }

  static RouteEntity _parseRoute(Map<String, dynamic> json) {
    return RouteEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      ref: json['ref'] as String,
      color: json['color'] as String?,
      polyline: (json['polyline'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((p) => Map<String, double>.from(p))
          .toList(),
      stops: (json['stops'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((s) => Map<String, double>.from(s))
          .toList(),
      description: json['description'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: json['created_at'] as DateTime?,
      updatedAt: json['updated_at'] as DateTime?,
    );
  }
}
