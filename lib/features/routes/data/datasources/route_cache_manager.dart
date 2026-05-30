import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

/// Gestor de caché local para rutas
/// Descarga todas las rutas de Firestore UNA SOLA VEZ y las guarda localmente
/// Usa patrón stale-while-revalidate: sirve caché aunque esté expirado y
/// refresca en background para no bloquear la UI al usuario.
class RouteCacheManager {
  static const String _cacheFileName = 'routes_cache_v2.json';
  static const Duration _cacheExpiration = Duration(days: 7);

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

  /// Carga rutas desde caché local (respeta expiración de 7 días)
  static Future<List<RouteEntity>> loadRoutesFromCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_cacheFileName');

      if (!file.existsSync()) {
        return [];
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Verificar expiración
      final timestamp = DateTime.parse(data['timestamp'] as String);
      if (DateTime.now().difference(timestamp) > _cacheExpiration) {
        print('⚠️ Caché expirado (>${_cacheExpiration.inDays} días)');
        return [];
      }

      // Parsear rutas
      final routesList = (data['routes'] as List).cast<Map<String, dynamic>>();
      final routes = routesList.map((r) => _parseRoute(r)).toList();

      print('✅ ${routes.length} rutas cargadas desde caché local');
      return routes;
    } catch (e) {
      print('❌ Error cargando rutas del caché: $e');
      return [];
    }
  }

  /// Carga rutas desde caché aunque esté expirado (stale-while-revalidate).
  /// Retorna una tupla: (routes, isExpired).
  /// - routes: lista de rutas (puede ser vacía si no hay caché)
  /// - isExpired: true si el caché existe pero está expirado
  static Future<({List<RouteEntity> routes, bool isExpired})>
  loadCacheWithStaleness() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_cacheFileName');

      if (!file.existsSync()) {
        return (routes: <RouteEntity>[], isExpired: false);
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final timestamp = DateTime.parse(data['timestamp'] as String);
      final isExpired = DateTime.now().difference(timestamp) > _cacheExpiration;

      final routesList = (data['routes'] as List).cast<Map<String, dynamic>>();
      final routes = routesList.map((r) => _parseRoute(r)).toList();

      if (isExpired) {
        print(
          '⚠️ Caché expirado, sirviendo datos stale (${routes.length} rutas)',
        );
      } else {
        print('✅ ${routes.length} rutas cargadas desde caché local (vigente)');
      }
      return (routes: routes, isExpired: isExpired);
    } catch (e) {
      print('❌ Error cargando caché con staleness: $e');
      return (routes: <RouteEntity>[], isExpired: false);
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
