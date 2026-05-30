import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

/// Servicio para calcular y gestionar bounding boxes de rutas.
/// Un bounding box es el rectángulo más pequeño que contiene todos los puntos de una ruta.
/// Se usa para filtrar rutas de forma eficiente en Firestore sin descargar todas.
class RouteBoundingBoxService {
  /// Calcula el bounding box de una ruta basándose en sus polyline y stops.
  /// Retorna la ruta actualizada con lat_min, lat_max, lng_min, lng_max.
  static RouteEntity calculateBoundingBox(RouteEntity route) {
    // Recolectar todos los puntos (polyline + stops)
    final allCoords = <LatLng>[];

    // Agregar puntos del polyline
    if (route.polyline != null && route.polyline!.isNotEmpty) {
      for (final coord in route.polyline!) {
        final lat = coord['lat'];
        final lng = coord['lng'];
        if (lat != null && lng != null) {
          allCoords.add(LatLng(lat, lng));
        }
      }
    }

    // Agregar puntos de paradas
    if (route.stops != null && route.stops!.isNotEmpty) {
      for (final stop in route.stops!) {
        final lat = stop['lat'];
        final lng = stop['lng'];
        if (lat != null && lng != null) {
          allCoords.add(LatLng(lat, lng));
        }
      }
    }

    // Si no hay coordenadas, retornar sin cambios
    if (allCoords.isEmpty) {
      return route.copyWith(latMin: 0, latMax: 0, lngMin: 0, lngMax: 0);
    }

    // Calcular min/max de latitud y longitud
    double latMin = allCoords[0].latitude;
    double latMax = allCoords[0].latitude;
    double lngMin = allCoords[0].longitude;
    double lngMax = allCoords[0].longitude;

    for (final point in allCoords) {
      latMin = point.latitude < latMin ? point.latitude : latMin;
      latMax = point.latitude > latMax ? point.latitude : latMax;
      lngMin = point.longitude < lngMin ? point.longitude : lngMin;
      lngMax = point.longitude > lngMax ? point.longitude : lngMax;
    }

    // Agregar pequeño margen para evitar cortes exactos
    const margin = 0.001; // ~100 metros
    return route.copyWith(
      latMin: latMin - margin,
      latMax: latMax + margin,
      lngMin: lngMin - margin,
      lngMax: lngMax + margin,
    );
  }

  /// Calcula bounding boxes para un lote de rutas.
  static List<RouteEntity> calculateBoundingBoxes(List<RouteEntity> routes) {
    return routes.map((route) => calculateBoundingBox(route)).toList();
  }

  /// Verifica si un punto está dentro del bounding box de la ruta.
  static bool isPointInBbox(RouteEntity route, LatLng point) {
    if (route.latMin == null ||
        route.latMax == null ||
        route.lngMin == null ||
        route.lngMax == null) {
      return false;
    }
    return point.latitude >= route.latMin! &&
        point.latitude <= route.latMax! &&
        point.longitude >= route.lngMin! &&
        point.longitude <= route.lngMax!;
  }
}
