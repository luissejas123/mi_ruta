import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:mi_ruta/features/routes/data/datasources/route_datasource.dart';

class RouteMigrationService {
  final RouteDatasource _datasource;

  RouteMigrationService({required RouteDatasource datasource})
    : _datasource = datasource;

  /// Migra las rutas desde el archivo JSON local a Firestore
  /// Retorna el número de rutas migradas exitosamente
  Future<int> migrateRoutesFromJson({required String assetPath}) async {
    try {
      // Leer archivo JSON del assets
      final jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> jsonList = jsonDecode(jsonString);

      int successCount = 0;

      for (final routeData in jsonList) {
        try {
          final name = routeData['name'] ?? 'Ruta ${routeData['ref']}';
          final ref = routeData['ref'] ?? '';
          final color = routeData['color'];

          // Procesar polyline (segments)
          List<Map<String, double>> polyline = [];
          if (routeData['segments'] != null && routeData['segments'] is List) {
            for (final segment in routeData['segments']) {
              if (segment is List) {
                for (final coord in segment) {
                  if (coord is List && coord.length >= 2) {
                    polyline.add({
                      'lat': (coord[0] ?? 0.0).toDouble(),
                      'lng': (coord[1] ?? 0.0).toDouble(),
                    });
                  }
                }
              }
            }
          }

          // Crear ruta en Firestore
          await _datasource.createRoute(
            name: name,
            ref: ref,
            color: color,
            polyline: polyline,
            description: 'Migrada desde assets',
          );

          successCount++;
        } catch (e) {
          print('Error al migrar ruta ${routeData['ref']}: $e');
          continue;
        }
      }

      return successCount;
    } catch (e) {
      throw Exception('Error al migrar rutas: $e');
    }
  }

  /// Verifica si las rutas ya existen en Firestore
  Future<bool> routesExistInFirestore() async {
    try {
      final routes = await _datasource.getAllRoutes();
      return routes.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
