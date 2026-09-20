import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/routes/domain/entities/planned_trip.dart';

class PlannedTripDatasource {
  final FirebaseFirestore _firestore;

  PlannedTripDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference _col(String userId) =>
      _firestore.collection('planned_trips').doc(userId).collection('trips');

  Future<void> save(PlannedTrip trip) async {
    await _col(trip.userId).doc(trip.id).set(_toMap(trip));
  }

  Future<List<PlannedTrip>> getAll(String userId) async {
    final snap = await _col(userId).limit(50).get();
    final plans = snap.docs.map((d) => _fromDoc(d, userId)).toList();
    plans.sort((a, b) {
      final aTime = a.scheduledAt ?? a.createdAt;
      final bTime = b.scheduledAt ?? b.createdAt;
      return aTime.compareTo(bTime);
    });
    return plans;
  }

  Future<void> markCompleted(String userId, String tripId) async {
    await _col(userId).doc(tripId).update({'is_completed': true});
  }

  Future<void> markCancelled(String userId, String tripId) async {
    await _col(userId).doc(tripId).update({
      'is_cancelled': true,
      'cancelled_at': DateTime.now().toIso8601String(),
    });
  }

  /// Cancelled plans for a user, most recently cancelled first.
  /// Filters `is_cancelled` in memory (no orderBy in the query) to avoid
  /// requiring a composite Firestore index, matching this project's
  /// convention for filtered subcollection queries.
  Future<List<PlannedTrip>> getCancelled(String userId) async {
    final snap =
        await _col(userId).where('is_cancelled', isEqualTo: true).get();
    final trips = snap.docs.map((d) => _fromDoc(d, userId)).toList();
    trips.sort((a, b) => (b.cancelledAt ?? b.createdAt)
        .compareTo(a.cancelledAt ?? a.createdAt));
    return trips;
  }

  Future<void> delete(String userId, String tripId) async {
    await _col(userId).doc(tripId).delete();
  }

  Map<String, dynamic> _toMap(PlannedTrip t) => {
    'origin_name': t.originName,
    'origin_lat': t.originLatLng.latitude,
    'origin_lng': t.originLatLng.longitude,
    'destination_name': t.destinationName,
    'destination_lat': t.destinationLatLng.latitude,
    'destination_lng': t.destinationLatLng.longitude,
    'legs': t.legs.map(_legToMap).toList(),
    'created_at': t.createdAt.toIso8601String(),
    'scheduled_at': t.scheduledAt?.toIso8601String(),
    'is_completed': t.isCompleted,
        'is_cancelled': t.isCancelled,
        'cancelled_at': t.cancelledAt?.toIso8601String(),
  };

  Map<String, dynamic> _legToMap(PlannedTripLeg l) => {
    'leg_type': l.type.name,
    'route_id': l.routeId,
    'route_name': l.routeName,
    'route_ref': l.routeRef,
    'direction_id': l.directionId,
    'boarding_lat': l.boardingPoint.latitude,
    'boarding_lng': l.boardingPoint.longitude,
    'alighting_lat': l.alightingPoint.latitude,
    'alighting_lng': l.alightingPoint.longitude,
    'walk_to_meters': l.walkToMeters,
    'transit_meters': l.transitMeters,
    'walk_from_meters': l.walkFromMeters,
  };

  PlannedTrip _fromDoc(DocumentSnapshot doc, String userId) {
    final d = doc.data() as Map<String, dynamic>;
    final rawLegs = (d['legs'] as List).cast<Map<String, dynamic>>();
    return PlannedTrip(
      id: doc.id,
      userId: userId,
      originName: d['origin_name'] as String,
      originLatLng: LatLng(
        d['origin_lat'] as double,
        d['origin_lng'] as double,
      ),
      destinationName: d['destination_name'] as String,
      destinationLatLng: LatLng(
        d['destination_lat'] as double,
        d['destination_lng'] as double,
      ),
      legs: rawLegs.map(_legFromMap).toList(),
      createdAt: DateTime.parse(d['created_at'] as String),
      scheduledAt: d['scheduled_at'] is String
          ? DateTime.tryParse(d['scheduled_at'] as String)
          : null,
      isCompleted: d['is_completed'] as bool? ?? false,
      isCancelled: d['is_cancelled'] as bool? ?? false,
      cancelledAt: d['cancelled_at'] != null
          ? DateTime.parse(d['cancelled_at'] as String)
          : null,
    );
  }

  PlannedTripLeg _legFromMap(Map<String, dynamic> m) {
    final typeStr = m['leg_type'] as String? ?? 'bus';
    final type = typeStr == 'walking' ? LegType.walking : LegType.bus;
    return PlannedTripLeg(
      type: type,
      routeId: m['route_id'] as String? ?? '',
      routeName: m['route_name'] as String? ?? '',
      routeRef: m['route_ref'] as String? ?? '',
      directionId: m['direction_id'] as String?,
      boardingPoint: LatLng(
        m['boarding_lat'] as double,
        m['boarding_lng'] as double,
      ),
      alightingPoint: LatLng(
        m['alighting_lat'] as double,
        m['alighting_lng'] as double,
      ),
      walkToMeters: (m['walk_to_meters'] as num?)?.toDouble() ?? 0,
      transitMeters: (m['transit_meters'] as num).toDouble(),
      walkFromMeters: (m['walk_from_meters'] as num?)?.toDouble() ?? 0,
    );
  }
}
