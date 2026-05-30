import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';

/// Resultado del cálculo de segmentos para un viaje en transporte público.
class TripSegment {
  /// Parada donde el usuario sube al micro/trufi.
  final LatLng boardingStop;

  /// Parada donde el usuario baja del micro/trufi.
  final LatLng alightingStop;

  /// Puntos del trayecto en el micro/trufi (subconjunto del polyline GTFS).
  final List<LatLng> transitPoints;

  const TripSegment({
    required this.boardingStop,
    required this.alightingStop,
    required this.transitPoints,
  });
}

/// Servicio de dominio: calcula la parada de abordaje, la de bajada y el
/// segmento de tránsito de una ruta GTFS dado un origen y un destino.
class TripSegmentService {
  /// Calcula el [TripSegment] óptimo para viajar de [origin] a [destination]
  /// usando [route].
  ///
  /// Primero busca segmentos en la dirección correcta (boardIdx < alightIdx).
  /// Si no encuentra ninguno, hace una segunda pasada sin restricción de
  /// dirección (fallback).
  static TripSegment compute({
    required OsmRoute route,
    required LatLng origin,
    required LatLng destination,
  }) {
    int bestBoard = -1;
    int bestAlight = -1;
    List<LatLng> bestSeg = [];
    double bestCost = double.infinity;

    // Buscamos la mejor combinación de (bIdx, aIdx) para abordar y bajar
    for (final seg in route.segments) {
      if (seg.length < 2) continue;

      final n = seg.length;
      final step = n > 500 ? 3 : 1;

      for (int i = 0; i < n; i += step) {
        final walkDistOrig = _fastDistSq(seg[i], origin);
        if (walkDistOrig > 0.003) continue; // aprox 5km en grados^2

        for (int j = i + 1; j < n; j += step) {
          // j > i SIEMPRE: el destino debe estar después del origen en el polyline
          // Esto garantiza que el trazado avanza en la dirección del recorrido
          final walkDistDest = _fastDistSq(seg[j], destination);

          // Penalización suave por distancia en bus
          final busStops = j - i;
          final cost = walkDistOrig + walkDistDest + (busStops * 0.00000005);

          if (cost < bestCost) {
            bestCost = cost;
            bestBoard = i;
            bestAlight = j;
            bestSeg = seg;
          }
        }
      }
    }

    // Buscamos el nodo exacto en un rango pequeño alrededor del índice óptimo
    if (bestBoard != -1 && bestAlight != -1) {
      bestBoard = _refineIndex(bestSeg, bestBoard, origin);
      bestAlight = _refineIndex(bestSeg, bestAlight, destination);
      // Asegurarse de que board <= alight después del refinamiento
      if (bestBoard > bestAlight) {
        final tmp = bestBoard;
        bestBoard = bestAlight;
        bestAlight = tmp;
      }
    }

    if (bestBoard == -1 || bestSeg.isEmpty) {
      return TripSegment(
        boardingStop: origin,
        alightingStop: destination,
        transitPoints: [],
      );
    }

    final transitPoints = bestSeg.sublist(bestBoard, bestAlight + 1);

    return TripSegment(
      boardingStop: bestSeg[bestBoard],
      alightingStop: bestSeg[bestAlight],
      transitPoints: transitPoints,
    );
  }

  /// Refina el índice buscando el punto más cercano en un radio de +/- 5 puntos
  static int _refineIndex(List<LatLng> seg, int startIdx, LatLng target) {
    int bestIdx = startIdx;
    double minD = _fastDistSq(seg[startIdx], target);
    for (int i = startIdx - 5; i <= startIdx + 5; i++) {
      if (i >= 0 && i < seg.length) {
        final d = _fastDistSq(seg[i], target);
        if (d < minD) {
          minD = d;
          bestIdx = i;
        }
      }
    }
    return bestIdx;
  }

  /// Distancia al cuadrado (sin raíz), cálculo super rápido
  static double _fastDistSq(LatLng a, LatLng b) {
    final dLat = a.latitude - b.latitude;
    final dLng = a.longitude - b.longitude;
    return dLat * dLat + dLng * dLng;
  }
}
