import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mi_ruta/features/driver/data/datasources/live_location_datasource.dart';

/// Publica la posición del chofer en servicio sin saturar Firestore.
///
/// El GPS entrega posiciones cada ~5 m; escribir cada una costaría muchas
/// escrituras. Se publica como máximo cada [minInterval] y siempre que la
/// unidad se movió al menos [minDistanceMeters]... o si pasó
/// [heartbeat] sin publicar (para que el pasajero sepa que sigue activa).
class LiveLocationPublisher {
  final LiveLocationDatasource _datasource;
  final Duration minInterval;
  final Duration heartbeat;
  final double minDistanceMeters;

  LiveLocationPublisher({
    required LiveLocationDatasource datasource,
    this.minInterval = const Duration(seconds: 5),
    this.heartbeat = const Duration(seconds: 45),
    this.minDistanceMeters = 15,
  }) : _datasource = datasource;

  DateTime? _lastSent;
  double? _lastLat;
  double? _lastLng;
  String? _activeVehicleId;

  /// Decide si una nueva posición debe publicarse (expuesto para tests).
  @visibleForTesting
  bool shouldPublish(
    double lat,
    double lng,
    DateTime now,
    double Function(double, double, double, double) distance,
  ) {
    if (_lastSent == null || _lastLat == null || _lastLng == null) return true;
    final elapsed = now.difference(_lastSent!);
    if (elapsed < minInterval) return false;
    if (elapsed >= heartbeat) return true;
    return distance(_lastLat!, _lastLng!, lat, lng) >= minDistanceMeters;
  }

  Future<void> onPosition({
    required String vehicleId,
    required String driverId,
    required double latitude,
    required double longitude,
    required double Function(double, double, double, double) distance,
    String? routeRef,
    String? routeName,
    double? heading,
  }) async {
    final now = DateTime.now();
    if (_activeVehicleId != vehicleId) {
      _activeVehicleId = vehicleId;
      _lastSent = null;
    }
    if (!shouldPublish(latitude, longitude, now, distance)) return;
    _lastSent = now;
    _lastLat = latitude;
    _lastLng = longitude;
    try {
      await _datasource.publish(
        vehicleId: vehicleId,
        driverId: driverId,
        latitude: latitude,
        longitude: longitude,
        routeRef: routeRef,
        routeName: routeName,
        heading: heading,
      );
    } catch (e) {
      // Sin la regla desplegada o sin red: no se interrumpe el servicio.
      debugPrint('[LiveLocation] no se pudo publicar: $e');
    }
  }

  /// Al detener el servicio la unidad desaparece del mapa de los pasajeros.
  Future<void> stop(String vehicleId) async {
    _lastSent = null;
    _activeVehicleId = null;
    try {
      await _datasource.remove(vehicleId);
    } catch (e) {
      debugPrint('[LiveLocation] no se pudo quitar la unidad: $e');
    }
  }
}
