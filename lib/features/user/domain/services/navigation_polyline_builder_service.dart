import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/utils/polyline_utils.dart';
import 'package:mi_ruta/features/user/domain/services/trip_phase_service.dart';

/// Servicio para construir polylines en la pantalla de navegación
class NavigationPolylineBuilderService {
  static final _transitColor = Color(0xFFFBC02D);

  /// Construye los polylines basado en la fase actual y posición del usuario
  static Set<Polyline> buildPolylines({
    required TripPhase phase,
    required LatLng? currentPosition,
    required List<LatLng> walkStartPoints,
    required List<LatLng> transitSegment,
    required List<LatLng> walkEndPoints,
  }) {
    final polylines = <Polyline>{};

    // Polyline de caminata inicial
    if (phase == TripPhase.walkStart && walkStartPoints.isNotEmpty) {
      final pts = currentPosition != null
          ? PolylineUtils.trimToPosition(walkStartPoints, currentPosition)
          : walkStartPoints;
      if (pts.length >= 2) {
        polylines.add(_buildWalkPolyline(id: 'walk_start', points: pts));
      }
    }

    // Polyline de transporte
    if (transitSegment.isNotEmpty &&
        (phase == TripPhase.walkStart || phase == TripPhase.onBus)) {
      final pts = (phase == TripPhase.onBus && currentPosition != null)
          ? PolylineUtils.trimToPosition(transitSegment, currentPosition)
          : transitSegment;
      if (pts.length >= 2) {
        polylines.add(_buildTransitPolyline(points: pts));
      }
    }

    // Polyline de caminata final
    if (walkEndPoints.isNotEmpty && phase != TripPhase.arrived) {
      final pts = (phase == TripPhase.walkEnd && currentPosition != null)
          ? PolylineUtils.trimToPosition(walkEndPoints, currentPosition)
          : walkEndPoints;
      if (pts.length >= 2) {
        polylines.add(_buildWalkPolyline(id: 'walk_end', points: pts));
      }
    }

    return polylines;
  }

  /// Crea un polyline de caminata (línea punteada gris)
  static Polyline _buildWalkPolyline({
    required String id,
    required List<LatLng> points,
  }) {
    return Polyline(
      polylineId: PolylineId(id),
      points: points,
      color: _getWalkColor(),
      width: 4,
      patterns: [PatternItem.dash(16), PatternItem.gap(12)],
    );
  }

  /// Crea un polyline de tránsito (línea amarilla sólida)
  static Polyline _buildTransitPolyline({required List<LatLng> points}) {
    return Polyline(
      polylineId: const PolylineId('transit'),
      points: points,
      color: _transitColor,
      width: 6,
    );
  }

  /// Retorna el color para polylines de caminata
  static Color _getWalkColor() {
    // Usando shade700 de gris
    return const Color(0xFF424242);
  }
}
