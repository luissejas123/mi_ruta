import 'package:mi_ruta/features/routes/data/datasources/route_datasource.dart';
import 'package:mi_ruta/features/routes/domain/services/route_bounding_box_service.dart';

/// Servicio para migrar datos de rutas existentes a la nueva estructura con bounding boxes.
/// Se ejecuta una sola vez cuando el usuario entra a la app por primera vez después de la actualización.
class RouteMigrationBboxService {
  final RouteDatasource _datasource;

  RouteMigrationBboxService({required RouteDatasource datasource})
    : _datasource = datasource;

  /// Migra todas las rutas activas calculando sus bounding boxes.
  /// Retorna el número de rutas migradas.
  Future<int> migrateRoutesToBoundingBoxes() async {
    try {
      print('⏳ Iniciando migración de bounding boxes...');

      // Obtener todas las rutas (en lotes para evitar OOM)
      final allRoutes = await _datasource.getAllActiveRoutesForMigration();
      print('📦 Rutas activas encontradas: ${allRoutes.length}');

      if (allRoutes.isEmpty) {
        print('ℹ️ No hay rutas para migrar');
        return 0;
      }

      print('🔢 Calculando bounding boxes para ${allRoutes.length} rutas...');

      // Calcular bounding boxes
      final routesWithBbox = RouteBoundingBoxService.calculateBoundingBoxes(
        allRoutes,
      );

      // Preparar datos para actualizar en Firestore
      final bboxMap = <String, Map<String, double>>{};
      int validBboxCount = 0;

      for (final route in routesWithBbox) {
        print(
          '  📍 Ruta ${route.name}: lat[${route.latMin?.toStringAsFixed(4)}, ${route.latMax?.toStringAsFixed(4)}], lng[${route.lngMin?.toStringAsFixed(4)}, ${route.lngMax?.toStringAsFixed(4)}]',
        );

        if (route.latMin != null &&
            route.latMax != null &&
            route.lngMin != null &&
            route.lngMax != null) {
          bboxMap[route.id] = {
            'lat_min': route.latMin!,
            'lat_max': route.latMax!,
            'lng_min': route.lngMin!,
            'lng_max': route.lngMax!,
          };
          validBboxCount++;
        }
      }

      print(
        '✅ Bounding boxes válidos calculados: $validBboxCount/${allRoutes.length}',
      );

      if (bboxMap.isEmpty) {
        print('❌ No se pudieron calcular bounding boxes válidos');
        return 0;
      }

      // Actualizar campos en colección principal routes
      print(
        '📤 Subiendo $validBboxCount bounding boxes a Firestore (routes)...',
      );
      await _datasource.updateBoundingBoxes(bboxMap);

      // Crear colección ligera routes_bbox (sin polylines) para búsqueda sin OOM
      print('📤 Creando colección routes_bbox ligera...');
      final bboxMeta = <String, Map<String, dynamic>>{};
      for (final route in routesWithBbox) {
        if (route.latMin != null &&
            route.latMax != null &&
            route.lngMin != null &&
            route.lngMax != null) {
          bboxMeta[route.id] = {
            'name': route.name,
            'ref': route.ref,
            'active': true,
            'lat_min': route.latMin!,
            'lat_max': route.latMax!,
            'lng_min': route.lngMin!,
            'lng_max': route.lngMax!,
          };
        }
      }
      await _datasource.populateRoutesBboxCollection(bboxMeta);

      print(
        '✅ ✅ ✅ Migración completada: $validBboxCount rutas actualizadas + routes_bbox creada',
      );
      return validBboxCount;
    } catch (e, st) {
      print('❌ ❌ ❌ Error en migración: $e\n$st');
      rethrow;
    }
  }

  /// Verifica si la migración ya fue completada.
  /// Retorna true si routes_bbox existe Y las rutas tienen bounding boxes.
  Future<bool> isMigrationComplete() async {
    try {
      print('🔍 Verificando si la migración ya fue completada...');

      // Verificar primero si routes_bbox existe (colección ligera requerida)
      final bboxCollectionExists = await _datasource
          .isRoutesBboxCollectionPopulated();
      if (!bboxCollectionExists) {
        print('❌ routes_bbox no existe aún — migración pendiente');
        return false;
      }

      print('✅ routes_bbox existe — migración completa');
      return true;
    } catch (e) {
      print(
        '⚠️ Error verificando migración: $e, asumiendo que necesita migración',
      );
      return false;
    }
  }
}
