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
  static const _busStopPenalty = 0.00000005;

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

      // El costo se separa en una parte de abordaje y otra de bajada:
      // origin(i) - penalty*i + destination(j) + penalty*j.
      // Mantener el mejor i anterior permite obtener exactamente el mismo
      // mínimo en O(n), en lugar de probar todas las parejas en O(n²).
      var bestBoardCost = double.infinity;
      var candidateBoard = -1;
      var nextBoard = 0;
      for (int j = 1; j < n; j += step) {
        while (nextBoard < j) {
          final walkDistOrig = _fastDistSq(seg[nextBoard], origin);
          if (walkDistOrig <= 0.003) {
            final boardCost = walkDistOrig - (_busStopPenalty * nextBoard);
            if (boardCost < bestBoardCost) {
              bestBoardCost = boardCost;
              candidateBoard = nextBoard;
            }
          }
          nextBoard += step;
        }

        if (candidateBoard != -1) {
          final cost =
              bestBoardCost +
              _fastDistSq(seg[j], destination) +
              (_busStopPenalty * j);
          if (cost < bestCost) {
            bestCost = cost;
            bestBoard = candidateBoard;
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
