import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/services/trip_segment_service.dart';

void main() {
  test('mantiene el resultado del cálculo exhaustivo en una ruta larga', () {
    final points = List.generate(
      2000,
      (index) => LatLng(-17.40, -66.20 + index * 0.00001),
    );
    final route = OsmRoute(
      id: 1,
      name: 'Ruta de prueba',
      ref: '1',
      segments: [points],
    );

    final result = TripSegmentService.compute(
      route: route,
      origin: points[100],
      destination: points[1800],
    );
    final expected = _exhaustiveSelection(
      points,
      origin: points[100],
      destination: points[1800],
    );

    expect(result.transitPoints, isNotEmpty);
    expect(result.boardingStop, points[expected.$1]);
    expect(result.alightingStop, points[expected.$2]);
  });
}

(int, int) _exhaustiveSelection(
  List<LatLng> points, {
  required LatLng origin,
  required LatLng destination,
}) {
  const penalty = 0.00000005;
  const step = 3;
  var bestBoard = -1;
  var bestAlight = -1;
  var bestCost = double.infinity;

  for (var i = 0; i < points.length; i += step) {
    final originDistance = _distanceSquared(points[i], origin);
    if (originDistance > 0.003) continue;
    for (var j = i + 1; j < points.length; j += step) {
      final cost =
          originDistance +
          _distanceSquared(points[j], destination) +
          ((j - i) * penalty);
      if (cost < bestCost) {
        bestCost = cost;
        bestBoard = i;
        bestAlight = j;
      }
    }
  }

  bestBoard = _refine(points, bestBoard, origin);
  bestAlight = _refine(points, bestAlight, destination);
  return bestBoard <= bestAlight
      ? (bestBoard, bestAlight)
      : (bestAlight, bestBoard);
}

int _refine(List<LatLng> points, int start, LatLng target) {
  var best = start;
  var minimum = _distanceSquared(points[start], target);
  for (var index = start - 5; index <= start + 5; index++) {
    if (index < 0 || index >= points.length) continue;
    final distance = _distanceSquared(points[index], target);
    if (distance < minimum) {
      minimum = distance;
      best = index;
    }
  }
  return best;
}

double _distanceSquared(LatLng a, LatLng b) {
  final latitude = a.latitude - b.latitude;
  final longitude = a.longitude - b.longitude;
  return latitude * latitude + longitude * longitude;
}
