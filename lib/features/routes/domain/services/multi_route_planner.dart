import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/routes/domain/entities/planned_trip.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/services/trip_segment_service.dart';

/// Minimum walk distance to emit an explicit walking leg (shorter = noise).
const _minWalkToShow = 80.0;

class MultiRoutePlanner {
  // Permissive limits — the score function ranks results by walking cost so
  // we prefer short walks; these limits just define the search boundary.
  static const _maxBoardWalk = 1500.0;
  static const _maxAlightWalk = 1500.0;
  static const _maxTransfer = 600.0;
  static const _minTransit = 150.0;
  static const _sampleStep = 15;

  static Future<List<PlannedTrip>> planAsync({
    required String userId,
    required LatLng origin,
    required LatLng destination,
    required List<OsmRoute> originRoutes,
    required List<OsmRoute> destRoutes,
    required List<OsmRoute> midRoutes,
    required String originName,
    required String destName,
    required DateTime scheduledAt,
    int maxResults = 5,
  }) async {
    // Filter ALL SQL results whose polyline passes within maxWalk of the
    // endpoint (fast squared-distance, no haversine). No take() before the
    // filter — SQL order is insertion order so relevant routes can be at
    // position 30+. After filtering cap to 12 to keep combos manageable.
    final r1 = _near(originRoutes, origin, _maxBoardWalk).take(12).toList();
    final r2 = _near(midRoutes, origin, double.infinity).take(8).toList();
    final r3 = _near(destRoutes, destination, _maxAlightWalk).take(12).toList();

    final options = <_Plan>[];

    // ── 1-leg (direct bus) ────────────────────────────────────────────────
    final directSeen = <String>{};
    for (final r in [...r1, ...r3]) {
      await Future.delayed(Duration.zero);
      // Use name as fallback when ref is empty to avoid all routes sharing key "|null"
      final stableId = r.ref.isNotEmpty ? r.ref : r.name;
      final key = '$stableId|${r.directionId}';
      if (!directSeen.add(key)) continue;

      final seg = TripSegmentService.compute(
        route: r,
        origin: origin,
        destination: destination,
      );
      if (seg.transitPoints.isEmpty) continue;

      final walkTo = _dist(origin, seg.boardingStop);
      final walkFrom = _dist(seg.alightingStop, destination);
      if (walkTo > _maxBoardWalk) continue;

      final transit = _crow(seg.boardingStop, seg.alightingStop) * 1.3;
      if (transit < _minTransit) continue;

      options.add(
        _Plan(
          score: walkTo * 4 + transit + walkFrom * 4,
          legs: _buildLegs(
            origin: origin,
            destination: destination,
            busSegments: [_BusSeg(r, seg, walkTo, walkFrom)],
            transferPoints: [],
          ),
          userId: userId,
          originName: originName,
          originLatLng: origin,
          destName: destName,
          destLatLng: destination,
        ),
      );
    }

    // ── 2-leg (transfer) ──────────────────────────────────────────────────
    for (final ra in r1) {
      await Future.delayed(Duration.zero);
      for (final rb in r3) {
        if (_sameRef(ra, rb)) continue;
        final result = _findTransfer(ra, rb, origin, destination);
        if (result == null) continue;

        final (seg1, seg2, tPt) = result;
        final walk1 = _dist(origin, seg1.boardingStop);
        final walk2 = _dist(seg2.alightingStop, destination);
        if (walk1 > _maxBoardWalk || walk2 > _maxAlightWalk) continue;

        final t1 = _crow(seg1.boardingStop, seg1.alightingStop) * 1.3;
        final t2 = _crow(seg2.boardingStop, seg2.alightingStop) * 1.3;
        if (t1 < _minTransit || t2 < _minTransit) continue;

        final transferWalk = _dist(seg1.alightingStop, seg2.boardingStop);
        options.add(
          _Plan(
            score: walk1 * 4 + t1 + transferWalk * 3 + t2 + walk2 * 4,
            legs: _buildLegs(
              origin: origin,
              destination: destination,
              busSegments: [
                _BusSeg(ra, seg1, walk1, transferWalk),
                _BusSeg(rb, seg2, transferWalk, walk2),
              ],
              transferPoints: [tPt],
            ),
            userId: userId,
            originName: originName,
            originLatLng: origin,
            destName: destName,
            destLatLng: destination,
          ),
        );
      }
    }

    // ── 3-leg (two transfers) ─────────────────────────────────────────────
    for (final ra in r1) {
      await Future.delayed(Duration.zero);
      for (final rm in r2) {
        if (_sameRef(ra, rm)) continue;
        final res1 = _findTransfer(ra, rm, origin, destination);
        if (res1 == null) continue;
        final (seg1, segM, tPt1) = res1;

        final walk1 = _dist(origin, seg1.boardingStop);
        if (walk1 > _maxBoardWalk) continue;

        for (final rb in r3) {
          if (_sameRef(rm, rb) || _sameRef(ra, rb)) continue;
          final alightM = seg1.alightingStop;
          final res2 = _findTransfer(rm, rb, alightM, destination);
          if (res2 == null) continue;
          final (segM2, seg3, tPt2) = res2;

          // segM and segM2 should be the same middle route — merge check
          if (segM.boardingStop != segM2.boardingStop &&
              _dist(segM.boardingStop, segM2.boardingStop) > 200) {
            continue;
          }

          final transfer1 = _dist(seg1.alightingStop, segM2.boardingStop);
          final transfer2 = _dist(segM2.alightingStop, seg3.boardingStop);
          final walk3 = _dist(seg3.alightingStop, destination);
          if (walk3 > _maxAlightWalk) continue;

          final t1 = _crow(seg1.boardingStop, seg1.alightingStop) * 1.3;
          final tM = _crow(segM2.boardingStop, segM2.alightingStop) * 1.3;
          final t3 = _crow(seg3.boardingStop, seg3.alightingStop) * 1.3;
          if (t1 < _minTransit || tM < _minTransit || t3 < _minTransit)
            continue;

          options.add(
            _Plan(
              score:
                  walk1 * 4 +
                  t1 +
                  transfer1 * 3 +
                  tM +
                  transfer2 * 3 +
                  t3 +
                  walk3 * 4,
              legs: _buildLegs(
                origin: origin,
                destination: destination,
                busSegments: [
                  _BusSeg(ra, seg1, walk1, transfer1),
                  _BusSeg(rm, segM2, transfer1, transfer2),
                  _BusSeg(rb, seg3, transfer2, walk3),
                ],
                transferPoints: [tPt1, tPt2],
              ),
              userId: userId,
              originName: originName,
              originLatLng: origin,
              destName: destName,
              destLatLng: destination,
            ),
          );
        }
      }
    }

    // ── Dedup by stable ref combo, keep best score ────────────────────────
    final seen = <String, _Plan>{};
    for (final p in options) {
      final key = p.legs
          .where((l) => l.isBus)
          .map((l) => '${l.routeRef}|${l.directionId}')
          .join('+');
      if (!seen.containsKey(key) || p.score < seen[key]!.score) {
        seen[key] = p;
      }
    }

    final sorted = seen.values.toList()
      ..sort((a, b) => a.score.compareTo(b.score));

    return sorted
        .take(maxResults)
        .map(
          (p) => PlannedTrip(
            id: _id(),
            userId: p.userId,
            originName: p.originName,
            originLatLng: p.originLatLng,
            destinationName: p.destName,
            destinationLatLng: p.destLatLng,
            legs: p.legs,
            createdAt: DateTime.now(),
            scheduledAt: scheduledAt,
          ),
        )
        .toList();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Builds the final leg list.
  ///
  /// Structure per bus leg:
  ///   [WALK to boarding]   ← only for the FIRST bus leg
  ///   BUS
  ///   [WALK to next boarding OR to destination]  ← always after each bus leg
  ///
  /// This avoids the duplication bug where the transfer walk was emitted twice
  /// (once as "walkFrom" of bus N and again as "walkTo" of bus N+1).
  static List<PlannedTripLeg> _buildLegs({
    required LatLng origin,
    required LatLng destination,
    required List<_BusSeg> busSegments,
    required List<LatLng> transferPoints,
  }) {
    final legs = <PlannedTripLeg>[];
    final n = busSegments.length;

    for (int i = 0; i < n; i++) {
      final bs = busSegments[i];
      final route = bs.route;
      final seg = bs.seg;
      final isLast = i == n - 1;

      // ── Walk TO first boarding only ──────────────────────────────────────
      if (i == 0) {
        final walkTo = _dist(origin, seg.boardingStop);
        if (walkTo > _minWalkToShow) {
          legs.add(
            PlannedTripLeg.walk(
              from: origin,
              to: seg.boardingStop,
              meters: walkTo,
            ),
          );
        }
      }

      // ── Bus leg ──────────────────────────────────────────────────────────
      final transit = _crow(seg.boardingStop, seg.alightingStop) * 1.3;
      legs.add(
        PlannedTripLeg(
          type: LegType.bus,
          routeId: '${route.ref}|${route.directionId}',
          routeName: route.name,
          routeRef: route.ref,
          directionId: route.directionId,
          boardingPoint: seg.boardingStop,
          alightingPoint: seg.alightingStop,
          transitMeters: transit,
        ),
      );

      // ── Walk FROM alighting: transfer or final walk ──────────────────────
      // The next boarding point (or destination) is the natural endpoint.
      final walkEnd = isLast
          ? destination
          : busSegments[i + 1].seg.boardingStop;
      final walkFrom = _dist(seg.alightingStop, walkEnd);
      if (walkFrom > _minWalkToShow) {
        legs.add(
          PlannedTripLeg.walk(
            from: seg.alightingStop,
            to: walkEnd,
            meters: walkFrom,
          ),
        );
      }
    }

    return legs;
  }

  /// Samples [ra]'s polyline to find the best transfer point to [rb] such that
  /// [ra] takes you from [origin] toward [destination] and [rb] takes you the
  /// rest of the way. Returns (seg_ra, seg_rb, transferPoint) or null.
  static (TripSegment, TripSegment, LatLng)? _findTransfer(
    OsmRoute ra,
    OsmRoute rb,
    LatLng origin,
    LatLng destination,
  ) {
    final aPts = ra.allPoints;
    final bPts = rb.allPoints;
    if (aPts.isEmpty || bPts.isEmpty) return null;

    double bestScore = double.infinity;
    (TripSegment, TripSegment, LatLng)? best;

    for (int i = 0; i < aPts.length; i += _sampleStep) {
      final tPt = aPts[i];
      if (!_forward(origin, destination, tPt)) continue;

      // Find nearest point on rb to this candidate transfer point
      double minD = double.infinity;
      LatLng? nearB;
      for (int j = 0; j < bPts.length; j += _sampleStep) {
        final d = _dist(tPt, bPts[j]);
        if (d < minD) {
          minD = d;
          nearB = bPts[j];
          if (minD < 30) break;
        }
      }
      if (minD > _maxTransfer || nearB == null) continue;

      final seg1 = TripSegmentService.compute(
        route: ra,
        origin: origin,
        destination: tPt,
      );
      if (seg1.transitPoints.isEmpty) continue;

      final seg2 = TripSegmentService.compute(
        route: rb,
        origin: nearB,
        destination: destination,
      );
      if (seg2.transitPoints.isEmpty) continue;

      final t1 = _crow(seg1.boardingStop, seg1.alightingStop) * 1.3;
      final t2 = _crow(seg2.boardingStop, seg2.alightingStop) * 1.3;
      final score = t1 + minD * 2 + t2;

      if (score < bestScore) {
        bestScore = score;
        best = (seg1, seg2, tPt);
      }
    }
    return best;
  }

  /// Routes whose polyline has at least one point within [maxM] metres.
  /// Uses fast squared-degree distance (no haversine / no trig per point).
  static List<OsmRoute> _near(
    List<OsmRoute> routes,
    LatLng point,
    double maxM,
  ) {
    if (maxM == double.infinity) return routes;
    // Pre-compute threshold in degrees² (avoids sqrt per point)
    final cosLat = cos(point.latitude * pi / 180);
    final dLatMax = maxM / 111000;
    final dLngMax = maxM / (111000 * cosLat);
    final threshSq = dLatMax * dLatMax + dLngMax * dLngMax;
    return routes.where((r) {
      for (final seg in r.segments) {
        for (int i = 0; i < seg.length; i += 5) {
          final dLat = seg[i].latitude - point.latitude;
          final dLng = seg[i].longitude - point.longitude;
          if (dLat * dLat + dLng * dLng <= threshSq) return true;
        }
      }
      return false;
    }).toList();
  }

  static bool _sameRef(OsmRoute a, OsmRoute b) {
    if (a.ref.isNotEmpty && a.ref == b.ref) return true;
    if (a.name.isNotEmpty && a.name == b.name) return true;
    return false;
  }

  static bool _forward(LatLng origin, LatLng dest, LatLng pt) {
    final dx = dest.latitude - origin.latitude;
    final dy = dest.longitude - origin.longitude;
    final px = pt.latitude - origin.latitude;
    final py = pt.longitude - origin.longitude;
    return (dx * px + dy * py) >= 0;
  }

  static double _dist(LatLng a, LatLng b) => Geolocator.distanceBetween(
    a.latitude,
    a.longitude,
    b.latitude,
    b.longitude,
  );

  static double _crow(LatLng a, LatLng b) {
    final dLat = (b.latitude - a.latitude) * 111000;
    final dLng =
        (b.longitude - a.longitude) * 111000 * cos(a.latitude * pi / 180);
    return sqrt(dLat * dLat + dLng * dLng);
  }

  static int _counter = 0;
  static String _id() =>
      '${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
}

// ── Internal helpers ─────────────────────────────────────────────────────────

class _BusSeg {
  final OsmRoute route;
  final TripSegment seg;
  final double walkTo;
  final double walkFrom;
  const _BusSeg(this.route, this.seg, this.walkTo, this.walkFrom);
}

class _Plan {
  final double score;
  final List<PlannedTripLeg> legs;
  final String userId;
  final String originName;
  final LatLng originLatLng;
  final String destName;
  final LatLng destLatLng;
  const _Plan({
    required this.score,
    required this.legs,
    required this.userId,
    required this.originName,
    required this.originLatLng,
    required this.destName,
    required this.destLatLng,
  });
}
