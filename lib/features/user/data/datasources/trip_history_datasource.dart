import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/user/domain/entities/trip_history_entry.dart';

class TripHistoryDatasource {
  final FirebaseFirestore _firestore;

  TripHistoryDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference _trips(String userId) => _firestore
      .collection('trip_history')
      .doc(userId)
      .collection('trips');

  Future<void> saveTrip(TripHistoryEntry entry) async {
    await _trips(entry.userId).doc(entry.id).set({
      'route_name': entry.routeName,
      'origin_name': entry.originName,
      'destination_name': entry.destinationName,
      'elapsed_seconds': entry.elapsed.inSeconds,
      'date': entry.date.toIso8601String(),
      'fare_paid': entry.farePaid,
    });
  }

  Future<List<TripHistoryEntry>> getTrips(String userId) async {
    final snap = await _trips(userId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return TripHistoryEntry(
        id: doc.id,
        userId: userId,
        routeName: d['route_name'] as String,
        originName: d['origin_name'] as String? ?? 'Mi ubicación',
        destinationName: d['destination_name'] as String,
        elapsed: Duration(seconds: d['elapsed_seconds'] as int),
        date: DateTime.parse(d['date'] as String),
        farePaid: (d['fare_paid'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }
}
